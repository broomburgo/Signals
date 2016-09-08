public struct Unit: Hashable {
	public init() {}

	public var hashValue: Int {
		return "".hashValue
	}
}

public func == (lhs: Unit, rhs: Unit) -> Bool {
	return true
}
