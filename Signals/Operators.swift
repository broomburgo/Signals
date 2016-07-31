public class SignalMap<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> Next
	init<Observable: ObservableType where Observable.ObservedType == Previous>(root: Observable, transform: Previous -> Next) {
		self.root = AnyObservable(root)
		self.transform = transform
	}

	public func onNext(callback: Next -> SignalPersistence) -> Self {
		root.onNext { previous in
			return callback(self.transform(previous))
		}
		return self
	}
}

public class SignalFlatMap<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> AnyObservable<Next>
	private var dependentPersistence = SignalPersistence.Continue
	init<Observable: ObservableType, OtherObservable: ObservableType where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next>(root: Observable, transform: Previous -> OtherObservable) {
		self.root = AnyObservable(root)
		self.transform = { AnyObservable(transform($0)) }
	}

	public func onNext(callback: Next -> SignalPersistence) -> Self {
		root.onNext { previous in
			guard self.dependentPersistence != .Stop else { return .Stop }
			let newObservable = self.transform(previous)
			newObservable.onNext { [weak self] value in
				guard let this = self else { return .Stop }
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

	private let root: AnyObservable<Wrapped>
	private let predicate: Wrapped -> Bool
	init<Observable: ObservableType where Observable.ObservedType == Wrapped>(root: Observable, predicate: ObservedType -> Bool) {
		self.root = AnyObservable(root)
		self.predicate = predicate
	}

	public func onNext(callback: Wrapped -> SignalPersistence) -> Self {
		root.onNext { value in
			if self.predicate(value) {
				return callback(value)
			} else {
				return .Continue
			}
		}
		return self
	}
}

public class SignalCached<Wrapped>: ObservableType, SignalType {
	public typealias ObservedType = Wrapped
	public typealias SentType = Wrapped

	private let rootObservable: AnyObservable<Wrapped>
	private let rootSignal: AnySignal<Wrapped>
	private var cachedValue: Wrapped? = nil
	private var dependentPersistence = SignalPersistence.Continue
	private var ignoreFirst: Bool = false
	init<Observable: ObservableType, Signal: SignalType where Observable.ObservedType == Wrapped, Signal.SentType == Wrapped>(rootObservable: Observable, rootSignal: Signal) {
		self.rootObservable = AnyObservable(rootObservable)
		self.rootSignal = AnySignal(rootSignal)
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .Stop }
			guard this.ignoreFirst == false else { return .Stop }
			guard this.dependentPersistence != .Stop else { return .Stop }
			this.cachedValue = value
			return this.dependentPersistence
		}
	}

	public func onNext(callback: Wrapped -> SignalPersistence) -> Self {
		ignoreFirst = true
		if let cached = cachedValue {
			dependentPersistence = callback(cached)
		}
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .Stop }
			guard this.dependentPersistence != .Stop else { return .Stop }
			this.cachedValue = value
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}

		return self
	}

	public func send(value: Wrapped) -> Self {
		rootSignal.send(value)
		return self
	}
}
