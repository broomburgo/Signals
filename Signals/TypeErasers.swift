class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped
	func onNext(callback: ObservedType -> SignalPersistence) -> Self {
		fatalError()
	}
}

class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {
	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	override func onNext(callback: ObservedType -> SignalPersistence) -> Self {
		base.onNext(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped
	private let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType where Observable.ObservedType == ObservedType>(_ base: Observable) {
		self.box = BoxObservable(base: base)
	}

	public func onNext(callback: ObservedType -> SignalPersistence) -> Self {
		box.onNext(callback)
		return self
	}
}

class BoxSignalBase<Wrapped>: SignalType {
	typealias SentType = Wrapped
	func send(value: SentType) -> Self {
		fatalError()
	}
}

class BoxSignal<Signal: SignalType>: BoxSignalBase<Signal.SentType> {
	let base: Signal
	init(base: Signal) {
		self.base = base
	}

	override func send(value: SentType) -> Self {
		base.send(value)
		return self
	}
}

public class AnySignal<Wrapped>: SignalType {
	public typealias SentType = Wrapped
	private let box: BoxSignalBase<Wrapped>

	public init<Signal: SignalType where Signal.SentType == SentType>(_ base: Signal) {
		self.box = BoxSignal(base: base)
	}

	public func send(value: SentType) -> Self {
		box.send(value)
		return self
	}
}
