public enum Persistence {
	case stop
	case again
}

private class FixedEmitter<Wrapped>: VariableType, ObservableType {
	typealias WrappedType = Wrapped
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

public class Emitter<Wrapped>: VariableType, ObservableType {
	public typealias WrappedType = Wrapped
	public typealias ObservedType = Wrapped

	fileprivate let workerQueue = DispatchQueue.global()
	fileprivate let callbackQueue: DispatchQueue
	fileprivate var fixed: [FixedEmitter<WrappedType>] = []

	public init(callbackQueue: DispatchQueue = DispatchQueue.main) {
		self.callbackQueue = callbackQueue
	}

	@discardableResult
	public func update(_ value: WrappedType) -> Self {
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
	public func onNext(_ callback: @escaping (WrappedType) -> Persistence) -> Self {
		fixed.append(FixedEmitter<WrappedType>().onNext(callback))
		return self
	}
}
