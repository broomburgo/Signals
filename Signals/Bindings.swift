public protocol BindableType {
	associatedtype BoundType
	func bind<Observable: ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType
}

extension SignalType where Self: BindableType, SentType == Self.BoundType {
	public func bind<Observable : ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType {
		observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			this.send(value)
			return .continue
		}
	}
}

extension Signal: BindableType {
	public typealias BoundType = SentType
}

extension SignalCached: BindableType {
	public typealias BoundType = SentType
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
			return .continue
		}
	}
}
