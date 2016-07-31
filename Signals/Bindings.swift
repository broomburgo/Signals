public protocol BindableType {
	associatedtype BoundType
	func bind<Observable: ObservableType where Observable.ObservedType == BoundType>(to observable: Observable)
}

extension SignalType where Self: BindableType, SentType == Self.BoundType {
	public func bind<Observable : ObservableType where Observable.ObservedType == BoundType>(to observable: Observable) {
		observable.onNext { [weak self] value in
			guard let this = self else { return .Stop }
			this.send(value)
			return .Continue
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

	private let bindCallback: Bound -> ()
	public init(bindCallback: Bound -> ()) {
		self.bindCallback = bindCallback
	}

	public func bind<Observable : ObservableType where Observable.ObservedType == BoundType>(to observable: Observable) {
		observable.onNext { [weak self] value in
			guard let this = self else { return .Stop }
			this.bindCallback(value)
			return .Continue
		}
	}
}
