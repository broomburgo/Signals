import Foundation

public enum SignalPersistence {
	case Stop
	case Continue
}

class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped
	func observe(callback: ObservedType -> SignalPersistence) -> Self {
		fatalError()
	}
}

class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {
	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	override func observe(callback: ObservedType -> SignalPersistence) -> Self {
		base.observe(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped
	private let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType where Observable.ObservedType == ObservedType>(_ base: Observable) {
		self.box = BoxObservable(base: base)
	}

	public func observe(callback: ObservedType -> SignalPersistence) -> Self {
		box.observe(callback)
		return self
	}
}

private class FixedSignal<Wrapped>: ObservableType, SignalType {
	typealias ObservedType = Wrapped
	typealias SentType = Wrapped
	typealias Observation = ObservedType -> SignalPersistence

	var observation: (ObservedType -> SignalPersistence)? = nil

	func observe(callback: ObservedType -> SignalPersistence) -> Self {
		guard observation == nil else { return self }
		observation = callback
		return self
	}

	func send(value: ObservedType) -> Self {
		if let persistence = observation?(value) {
			switch persistence {
			case .Stop:
				observation = nil
			case .Continue:
				break
			}
		}
		return self
	}

	var isActive: Bool {
		return observation != nil
	}
}

public class AbstractSignal<Wrapped>: SignalType {
	public typealias SentType = Wrapped

	private let workerQueue: dispatch_queue_t
	private let callbackQueue: dispatch_queue_t
	private var fixed: [FixedSignal<SentType>] = []

	init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		self.workerQueue = workerQueue
		self.callbackQueue = callbackQueue
	}

	func observeBase(callback: SentType -> SignalPersistence) -> Self {
		fixed.append(FixedSignal<SentType>().observe(callback))
		return self
	}

	public func send(value: SentType) -> Self {
		dispatch_async(workerQueue) {
			for signal in self.fixed {
				dispatch_async(self.callbackQueue) {
					signal.send(value)
				}
			}
			dispatch_async(self.callbackQueue) {
				self.fixed = self.fixed.filter { $0.isActive }
			}
		}
		return self
	}
}

public class Signal<Wrapped>: AbstractSignal<Wrapped>, ObservableType {
	public typealias ObservedType = Wrapped

	public override init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		super.init(workerQueue: workerQueue, callbackQueue: callbackQueue)
	}

	public func observe(callback: SentType -> SignalPersistence) -> Self {
		observeBase(callback)
		return self
	}
}
