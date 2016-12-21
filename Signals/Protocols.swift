public protocol ObservableType: class {
	associatedtype ObservedType
	@discardableResult func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self
}

public protocol VariableType: class {
	associatedtype WrappedType
	@discardableResult func update(_ value: WrappedType) -> Self
}

extension ObservableType {
	public var any: AnyObservable<ObservedType> {
		return AnyObservable(self)
	}

	public var single: SingleObservable<ObservedType> {
		return SingleObservable(root: self)
	}

	public func map<Other>(_ transform: @escaping (ObservedType) -> Other) -> MapObservable<ObservedType,Other> {
		return MapObservable(root: self, transform: transform)
	}

	public func flatMap<OtherObservable: ObservableType>(_ transform: @escaping (ObservedType) -> OtherObservable) -> FlatMapObservable<ObservedType,OtherObservable.ObservedType> {
		return FlatMapObservable(root: self, transform: transform)
	}

	public func filter(_ predicate: @escaping (ObservedType) -> Bool) -> FilterObservable<ObservedType> {
		return FilterObservable(root: self, predicate: predicate)
	}
}

extension ObservableType where Self: VariableType, ObservedType == Self.WrappedType {
	public var cached: CachedObservable<ObservedType> {
		return CachedObservable<ObservedType>(rootObservable: self, rootVariable: self)
	}
}
