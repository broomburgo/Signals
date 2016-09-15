public protocol ObservableType: class {
	associatedtype ObservedType
	@discardableResult func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self
}

public protocol SignalType: class {
	associatedtype SentType
	@discardableResult func send(_ value: SentType) -> Self
}

extension ObservableType {
	public var observable: AnyObservable<ObservedType> {
		return AnyObservable(self)
	}

	public func map<Other>(_ transform: @escaping (ObservedType) -> Other) -> AnyObservable<Other> {
		return AnyObservable(SignalMap(root: self, transform: transform))
	}

	public func flatMap<OtherObservable: ObservableType>(_ transform: @escaping (ObservedType) -> OtherObservable) -> AnyObservable<OtherObservable.ObservedType> {
		return AnyObservable(SignalFlatMap(root: self, transform: transform))
	}

	public func filter(_ predicate: @escaping (ObservedType) -> Bool) -> AnyObservable<ObservedType> {
		return AnyObservable(SignalFilter(root: self, predicate: predicate))
	}
}

extension ObservableType {
	public var single: Deferred<ObservedType> {
		let deferred = Deferred<ObservedType>()
		onNext { (value) -> SignalPersistence in
			deferred.fill(value)
			return .stop
		}
		return deferred
	}
}

extension ObservableType where Self: SignalType, ObservedType == Self.SentType {
	public var cached: SignalCached<ObservedType> {
		return SignalCached<ObservedType>(rootObservable: self, rootSignal: self)
	}

	public var single: Deferred<ObservedType> {
		return Deferred(nil,self)
	}
}
