extension Dictionary {
	public func isEqual(to other: [Key:Value], considering predicate: (Value,Value) -> Bool) -> Bool {
		guard self.count == other.count else { return false }
		for key in keys {
			let selfValue = self[key]
			let otherValue = other[key]
			switch (selfValue,otherValue) {
			case (.some,.none):
				return false
			case (.none,.some):
				return false
			case let (.some(left),.some(right)):
				if predicate(left,right) == false {
					return false
				}
			default:
				break
			}
		}
		return true
	}
}

extension Dictionary where Value: Equatable {
	public func isEqual(to other: [Key:Value]) -> Bool {
		return isEqual(to: other, considering: ==)
	}
}

extension Dictionary: Monoid {
	public func compose(_ other: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
		var m_dict = self
		for (key,value) in other {
			m_dict[key] = value
		}
		return m_dict
	}

	public static var empty: Dictionary<Key, Value> {
		return [:]
	}
}
