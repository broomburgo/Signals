import Foundation

public final class Receiver<Wrapped>: VariableType {
	public typealias VariedType = Wrapped

	private var value: Wrapped?

	public init(value: Wrapped? = nil) {
		self.value = value
	}

	@discardableResult
	public func update(_ value: Wrapped) -> Self {
		self.value = value
		return self
	}

	public var get: Wrapped? {
		return value
	}
}

public final class Listener<Wrapped>: VariableType {
	public typealias VariedType = Wrapped

	private let callback: (Wrapped) -> ()
	public init(_ callback: @escaping (Wrapped) -> ()) {
		self.callback = callback
	}

	@discardableResult
	public func update(_ value: Wrapped) -> Self {
		callback(value)
		return self
	}
}
