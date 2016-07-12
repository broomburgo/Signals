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
