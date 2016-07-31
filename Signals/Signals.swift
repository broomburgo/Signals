import Foundation

public enum SignalPersistence {
	case Stop
	case Continue
}

private class FixedSignal<Wrapped>: ObservableType, SignalType {
	typealias ObservedType = Wrapped
	typealias SentType = Wrapped
	typealias Observation = ObservedType -> SignalPersistence

	var observation: (ObservedType -> SignalPersistence)? = nil

	func onNext(callback: ObservedType -> SignalPersistence) -> Self {
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

public class Signal<Wrapped>: ObservableType, SignalType {
	public typealias ObservedType = Wrapped
	public typealias SentType = Wrapped

	private let workerQueue: dispatch_queue_t
	private let callbackQueue: dispatch_queue_t
	private var fixed: [FixedSignal<SentType>] = []

	public init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		self.workerQueue = workerQueue
		self.callbackQueue = callbackQueue
	}

	public func onNext(callback: SentType -> SignalPersistence) -> Self {
		fixed.append(FixedSignal<SentType>().onNext(callback))
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
