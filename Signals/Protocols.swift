public protocol CascadedType {
	func concatenate(_ value: Any)
}

public protocol ObservableType: class, CascadedType {
	associatedtype ObservedType
	@discardableResult func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self
}

public protocol VariableType: class {
	associatedtype VariedType
	@discardableResult func update(_ value: VariedType) -> Self
}

//MARK: - Main
extension ObservableType {
	public func onAll(_ callback: @escaping (ObservedType) -> ()) -> Self {
		return onNext(always(callback))
	}

	public var any: AnyObservable<ObservedType> {
		return AnyObservable(self)
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

	public func merge<Observable: ObservableType>(_ other: Observable) -> MergeObservable<ObservedType> where Observable.ObservedType == ObservedType {
		return MergeObservable(roots: AnyObservable(self),AnyObservable(other))
	}

	public func debounce(_ throttleDuration: Double) -> DebounceObservable<ObservedType> {
		return DebounceObservable(root: self, throttleDuration: throttleDuration)
	}

	public func combine<Observable: ObservableType>(_ other: Observable) -> Combine2Observable<ObservedType,Observable.ObservedType> {
		return Combine2Observable(root1Observable: self, root2Observable: other)
	}

	public var cached: CachedObservable<ObservedType> {
		return CachedObservable<ObservedType>(root: self)
	}
}

extension Sequence where Iterator.Element: ObservableType {
	public var mergeAll: MergeObservable<Iterator.Element.ObservedType> {
		return MergeObservable(roots: map(AnyWeakObservable.init))
	}
}

//MARK: - Derived
extension ObservableType {
	public func mapSome<Other>(_ transform: @escaping (ObservedType) -> Other?) -> MapObservable<Other?,Other> {
		return map(transform)
			.filter { $0 != nil }
			.map { $0! }
	}
}
