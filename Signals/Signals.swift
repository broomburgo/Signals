import Foundation

public enum SignalPersistence {
	case stop
	case `continue`
}

private class FixedSignal<Wrapped>: ObservableType, SignalType {
	typealias ObservedType = Wrapped
	typealias SentType = Wrapped
	typealias Observation = (ObservedType) -> SignalPersistence

	var observation: ((ObservedType) -> SignalPersistence)? = nil

	func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		guard observation == nil else { return self }
		observation = callback
		return self
	}

	func send(_ value: ObservedType) -> Self {
		if let persistence = observation?(value) {
			switch persistence {
			case .stop:
				observation = nil
			case .continue:
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

	fileprivate let workerQueue: DispatchQueue
	fileprivate let callbackQueue: DispatchQueue
	fileprivate var fixed: [FixedSignal<SentType>] = []

	public init(workerQueue: DispatchQueue = DispatchQueue.global(), callbackQueue: DispatchQueue = DispatchQueue.main) {
		self.workerQueue = workerQueue
		self.callbackQueue = callbackQueue
	}

	public func onNext(_ callback: @escaping (SentType) -> SignalPersistence) -> Self {
		fixed.append(FixedSignal<SentType>().onNext(callback))
		return self
	}

	public func send(_ value: SentType) -> Self {
		workerQueue.async {
			for signal in self.fixed {
				self.callbackQueue.async {
					_ = signal.send(value)
				}
			}
			self.callbackQueue.async {
				self.fixed = self.fixed.filter { $0.isActive }
			}
		}
		return self
	}
}
