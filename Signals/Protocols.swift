public protocol ObservableType: class {
	associatedtype ObservedType
	@discardableResult func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self
}

public protocol VariableType: class {
	associatedtype WrappedType
	@discardableResult func update(_ value: WrappedType) -> Self
}

extension ObservableType {
	public func map<Other>(_ transform: @escaping (ObservedType) -> Other) -> AnyObservable<Other> {
		return AnyObservable(MapObservable(root: self, transform: transform))
	}

	public func flatMap<OtherObservable: ObservableType>(_ transform: @escaping (ObservedType) -> OtherObservable) -> AnyObservable<OtherObservable.ObservedType> {
		return AnyObservable(FlatMapObservable(root: self, transform: transform))
	}

	public func filter(_ predicate: @escaping (ObservedType) -> Bool) -> AnyObservable<ObservedType> {
		return AnyObservable(FilterObservable(root: self, predicate: predicate))
	}

	public var single: SingleObservable<ObservedType> {
		return SingleObservable(root: self)
	}
}

extension ObservableType where Self: VariableType, ObservedType == Self.WrappedType {
	public var cached: CachedVariable<ObservedType> {
		return CachedVariable<ObservedType>(rootObservable: self, rootVariable: self)
	}
}
