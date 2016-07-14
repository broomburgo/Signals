public class SignalMap<Previous,Next>: AbstractSignal<Previous>, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> Next
	private init<Observable: ObservableType where Observable.ObservedType == Previous>(root: Observable, transform: Previous -> Next) {
		self.root = AnyObservable(root)
		self.transform = transform
	}

	public func observe(callback: Next -> SignalPersistence) -> Self {
		root.observe { previous in
			return callback(self.transform(previous))
		}
		return self
	}
}

public class SignalFlatMap<Previous,Next>: AbstractSignal<Previous>, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> AnyObservable<Next>
	private var dependentPersistence = SignalPersistence.Continue
	private init<Observable: ObservableType, OtherObservable: ObservableType where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next>(root: Observable, transform: Previous -> OtherObservable) {
		self.root = AnyObservable(root)
		self.transform = { AnyObservable(transform($0)) }
	}

	public func observe(callback: Next -> SignalPersistence) -> Self {
		root.observe { previous in
			guard self.dependentPersistence != .Stop else { return .Stop }
			let newObservable = self.transform(previous)
			newObservable.observe { [weak self] value in
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

public class SignalFilter<Wrapped>: AbstractSignal<Wrapped>, ObservableType {
	public typealias ObservedType = Wrapped

	private let root: AnyObservable<Wrapped>
	private let predicate: Wrapped -> Bool
	private init<Observable: ObservableType where Observable.ObservedType == Wrapped>(root: Observable, predicate: ObservedType -> Bool) {
		self.root = AnyObservable(root)
		self.predicate = predicate
	}

	public func observe(callback: Wrapped -> SignalPersistence) -> Self {
		root.observe { value in
			if self.predicate(value) {
				return callback(value)
			} else {
				return .Continue
			}
		}
		return self
	}
}

extension ObservableType {
	public func observable() -> AnyObservable<ObservedType> {
		return AnyObservable(self)
	}

	public func map<Other>(transform: ObservedType -> Other) -> AnyObservable<Other> {
		return AnyObservable(SignalMap(root: self, transform: transform))
	}

	public func flatMap<OtherObservable: ObservableType>(transform: ObservedType -> OtherObservable) -> AnyObservable<OtherObservable.ObservedType> {
		return AnyObservable(SignalFlatMap(root: self, transform: transform))
	}

	public func filter(predicate: ObservedType -> Bool) -> AnyObservable<ObservedType> {
		return AnyObservable(SignalFilter(root: self, predicate: predicate))
	}
}
