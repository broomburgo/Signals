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
