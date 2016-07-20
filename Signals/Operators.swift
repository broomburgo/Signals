public class SignalMap<Previous,Next>: AbstractSignal<Previous>, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> Next
	init<Observable: ObservableType where Observable.ObservedType == Previous>(root: Observable, transform: Previous -> Next) {
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
	init<Observable: ObservableType, OtherObservable: ObservableType where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next>(root: Observable, transform: Previous -> OtherObservable) {
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
	init<Observable: ObservableType where Observable.ObservedType == Wrapped>(root: Observable, predicate: ObservedType -> Bool) {
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
