class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped
	@discardableResult func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		fatalError()
	}
}

class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {
	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	@discardableResult override func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		base.onNext(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped
	fileprivate let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType>(_ base: Observable) where Observable.ObservedType == ObservedType {
		self.box = BoxObservable(base: base)
	}

	@discardableResult public func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		box.onNext(callback)
		return self
	}
}

class BoxSignalBase<Wrapped>: SignalType {
	typealias SentType = Wrapped
	@discardableResult func send(_ value: SentType) -> Self {
		fatalError()
	}
}

class BoxSignal<Signal: SignalType>: BoxSignalBase<Signal.SentType> {
	let base: Signal
	init(base: Signal) {
		self.base = base
	}

	@discardableResult override func send(_ value: SentType) -> Self {
		base.send(value)
		return self
	}
}

public class AnySignal<Wrapped>: SignalType {
	public typealias SentType = Wrapped
	fileprivate let box: BoxSignalBase<Wrapped>

	public init<Signal: SignalType>(_ base: Signal) where Signal.SentType == SentType {
		self.box = BoxSignal(base: base)
	}

	@discardableResult public func send(_ value: SentType) -> Self {
		box.send(value)
		return self
	}
}
