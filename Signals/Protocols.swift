public protocol ObservableType: class {
	associatedtype ObservedType
	func onNext(callback: ObservedType -> SignalPersistence) -> Self
}

public protocol SignalType: class {
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

	public func zip<OtherObservable: ObservableType>(with other: OtherObservable) -> AnyObservable<(ObservedType,OtherObservable.ObservedType)> {
		return flatMap { selfValue in
			other.map { otherValue in
				(selfValue,otherValue)
			}
		}
	}
}

extension ObservableType where Self: SignalType, ObservedType == Self.SentType {
	public func cached() -> SignalCached<ObservedType> {
		return SignalCached<ObservedType>(rootObservable: self, rootSignal: self)
	}
}

extension Deferred: ObservableType {
	public typealias ObservedType = WrappedType

	public func onNext(callback: ObservedType -> SignalPersistence) -> Self {
		return upon {
			callback($0)
			return
		}
	}
}
