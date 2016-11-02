extension String: Monoid {
	public static var empty: String {
		return ""
	}

	public func compose(_ other: String) -> String {
		return self + other
	}
}

extension String {
	public var toInt: Int? {
		return Int(self)
	}
}
