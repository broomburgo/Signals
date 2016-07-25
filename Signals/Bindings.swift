public protocol BindableType {
	associatedtype BoundType
	func bind<Observable: ObservableType where Observable.ObservedType == BoundType>(to observable: Observable)
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

public final class Binding<Bound>: BindableType {
	public typealias BoundType = Bound

	private let bindCallback: Bound -> ()
	public init(bindCallback: Bound -> ()) {
		self.bindCallback = bindCallback
	}

	public func bind<Observable : ObservableType where Observable.ObservedType == BoundType>(to observable: Observable) {
		observable.observe { [weak self] value in
			guard let this = self else { return .Stop }
			this.bindCallback(value)
			return .Continue
		}
	}
}
