public class SignalMap<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyObservable<Previous>
	fileprivate let transform: (Previous) -> Next
	init<Observable: ObservableType>(root: Observable, transform: @escaping (Previous) -> Next) where Observable.ObservedType == Previous {
		self.root = AnyObservable(root)
		self.transform = transform
	}

	@discardableResult public func onNext(_ callback: @escaping (Next) -> SignalPersistence) -> Self {
		root.onNext { previous in
			return callback(self.transform(previous))
		}
		return self
	}
}

public class SignalFlatMap<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyObservable<Previous>
	fileprivate let transform: (Previous) -> AnyObservable<Next>
	fileprivate var dependentPersistence = SignalPersistence.continue
	init<Observable: ObservableType, OtherObservable: ObservableType>(root: Observable, transform: @escaping (Previous) -> OtherObservable) where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next {
		self.root = AnyObservable(root)
		self.transform = { AnyObservable(transform($0)) }
	}

	@discardableResult public func onNext(_ callback: @escaping (Next) -> SignalPersistence) -> Self {
		root.onNext { previous in
			guard self.dependentPersistence != .stop else { return .stop }
			let newObservable = self.transform(previous)
			newObservable.onNext { [weak self] value in
				guard let this = self else { return .stop }
				let newPersistence = callback(value)
				this.dependentPersistence = newPersistence
				return newPersistence
			}
			return self.dependentPersistence
		}
		return self
	}
}

public class SignalFilter<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyObservable<Wrapped>
	fileprivate let predicate: (Wrapped) -> Bool
	init<Observable: ObservableType>(root: Observable, predicate: @escaping (ObservedType) -> Bool) where Observable.ObservedType == Wrapped {
		self.root = AnyObservable(root)
		self.predicate = predicate
	}

	@discardableResult public func onNext(_ callback: @escaping (Wrapped) -> SignalPersistence) -> Self {
		root.onNext { value in
			if self.predicate(value) {
				return callback(value)
			} else {
				return .continue
			}
		}
		return self
	}
}

public class SignalCached<Wrapped>: ObservableType, SignalType {
	public typealias ObservedType = Wrapped
	public typealias SentType = Wrapped

	fileprivate let rootObservable: AnyObservable<Wrapped>
	fileprivate let rootSignal: AnySignal<Wrapped>
	fileprivate var cachedValue: Wrapped? = nil
	fileprivate var dependentPersistence = SignalPersistence.continue
	fileprivate var ignoreFirst: Bool = false
	init<Observable: ObservableType, Signal: SignalType>(rootObservable: Observable, rootSignal: Signal) where Observable.ObservedType == Wrapped, Signal.SentType == Wrapped {
		self.rootObservable = AnyObservable(rootObservable)
		self.rootSignal = AnySignal(rootSignal)
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.ignoreFirst == false else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			return this.dependentPersistence
		}
	}

	 @discardableResult public func onNext(_ callback: @escaping (Wrapped) -> SignalPersistence) -> Self {
		ignoreFirst = true
		if let cached = cachedValue {
			dependentPersistence = callback(cached)
		}
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}

		return self
	}

	@discardableResult public func send(_ value: Wrapped) -> Self {
		rootSignal.send(value)
		return self
	}
}
