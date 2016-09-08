extension String: Monoid {
	public static var empty: String {
		return ""
	}

	public func compose(other: String) -> String {
		return self + other
	}
}
