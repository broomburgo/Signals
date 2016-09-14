class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped
	func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		fatalError()
	}
}

class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {
	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	override func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		_ = base.onNext(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped
	fileprivate let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType>(_ base: Observable) where Observable.ObservedType == ObservedType {
		self.box = BoxObservable(base: base)
	}

	public func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		_ = box.onNext(callback)
		return self
	}
}

class BoxSignalBase<Wrapped>: SignalType {
	typealias SentType = Wrapped
	func send(_ value: SentType) -> Self {
		fatalError()
	}
}

class BoxSignal<Signal: SignalType>: BoxSignalBase<Signal.SentType> {
	let base: Signal
	init(base: Signal) {
		self.base = base
	}

	override func send(_ value: SentType) -> Self {
		_ = base.send(value)
		return self
	}
}

public class AnySignal<Wrapped>: SignalType {
	public typealias SentType = Wrapped
	fileprivate let box: BoxSignalBase<Wrapped>

	public init<Signal: SignalType>(_ base: Signal) where Signal.SentType == SentType {
		self.box = BoxSignal(base: base)
	}

	public func send(_ value: SentType) -> Self {
		_ = box.send(value)
		return self
	}
}
