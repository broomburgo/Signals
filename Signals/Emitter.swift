import Dispatch

private final class FixedEmitter<Wrapped>: Cascaded, VariableType, ObservableType {
	typealias VariedType = Wrapped
	typealias ObservedType = Wrapped

	var observation: ((ObservedType) -> Persistence)? = nil

	@discardableResult
	func update(_ value: ObservedType) -> Self {
		if let persistence = observation?(value) {
			switch persistence {
			case .stop:
				observation = nil
			case .again:
				break
			}
		}
		return self
	}

	@discardableResult
	func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		guard observation == nil else { return self }
		observation = callback
		return self
	}

	var isActive: Bool {
		return observation != nil
	}
}

public final class Emitter<Wrapped>: Cascaded, VariableType, ObservableType {
	public typealias VariedType = Wrapped
	public typealias ObservedType = Wrapped

	fileprivate let workerQueue = DispatchQueue.global()
	fileprivate let callbackQueue: DispatchQueue
	fileprivate var fixed: [FixedEmitter<VariedType>] = []

	public init(callbackQueue: DispatchQueue = .main) {
		self.callbackQueue = callbackQueue
	}

	@discardableResult
	public func update(_ value: VariedType) -> Self {
		workerQueue.sync {
			for emitter in self.fixed {
				self.callbackQueue.async {
					emitter.update(value)
				}
			}
			self.callbackQueue.async {
				self.fixed = self.fixed.filter { $0.isActive }
			}
		}
		return self
	}

	@discardableResult
	public func onNext(_ callback: @escaping (VariedType) -> Persistence) -> Self {
		fixed.append(FixedEmitter<VariedType>().onNext(callback))
		return self
	}
}

public final class Fulfilled<Wrapped>: Cascaded, ObservableType {

	public typealias ObservedType = Wrapped

	private let value: Wrapped
	public init(_ value: Wrapped) {
		self.value = value
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		DispatchQueue.main.async {
			_ = callback(self.value)
		}
		return self
	}
}
