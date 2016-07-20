public protocol ObservableType {
	associatedtype ObservedType
	func observe(callback: ObservedType -> SignalPersistence) -> Self
}

public protocol SignalType {
	associatedtype SentType
	func send(value: SentType) -> Self
}

public protocol DeferredType {
	associatedtype WrappedType

	var isFilled: Bool { get }
	func peek() -> WrappedType?
	func upon(callback: WrappedType -> ()) -> Self
}

public protocol FillableDeferredType: DeferredType {
	func fill(value: WrappedType) -> Self
}

public protocol BindableType {
	associatedtype BoundType
	func bind<Observable: ObservableType where Observable.ObservedType == BoundType>(to observable: Observable)
}

extension ObservableType {
	public func observable() -> AnyObservable<ObservedType> {
		return AnyObservable(self)
	}

	public func single() -> Deferred<ObservedType> {
		return Deferred(value: nil, observable: self)
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

extension Deferred: ObservableType {
	public typealias ObservedType = WrappedType

	public func observe(callback: ObservedType -> SignalPersistence) -> Self {
		return upon {
			callback($0)
			return
		}
	}
}

extension AbstractSignal: BindableType {
	public typealias BoundType = Wrapped
	public func bind<Observable : ObservableType where Observable.ObservedType == BoundType>(to observable: Observable) {
		observable.observe { [weak self] value in
			guard let this = self else { return .Stop }
			this.send(value)
			return .Continue
		}
	}
}
