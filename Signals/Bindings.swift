public protocol BindableType {
	associatedtype BoundType
	func bind<Observable: ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType
}

extension VariableType where Self: BindableType, WrappedType == Self.BoundType {
	public func bind<Observable : ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType {
		observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			this.update(value)
			return .again
		}
	}
}

extension Variable: BindableType {
	public typealias BoundType = WrappedType
}

extension CachedVariable: BindableType {
	public typealias BoundType = WrappedType
}

public final class Binding<Bound>: BindableType {
	public typealias BoundType = Bound

	fileprivate let bindCallback: (Bound) -> ()
	public init(bindCallback: @escaping (Bound) -> ()) {
		self.bindCallback = bindCallback
	}

	public func bind<Observable : ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType {
		observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			this.bindCallback(value)
			return .again
		}
	}
}
