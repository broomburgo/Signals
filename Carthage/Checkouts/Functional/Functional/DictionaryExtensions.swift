extension Dictionary {
	public func merged(with other: Dictionary) -> Dictionary {
		var m_dict = self
		for (key,value) in other {
			m_dict[key] = value
		}
		return m_dict
	}

	public func isEqual(to other: [Key:Value], considering predicate: (Value,Value) -> Bool) -> Bool {
		guard self.count == other.count else { return false }
		for key in keys {
			let selfValue = self[key]
			let otherValue = other[key]
			switch (selfValue,otherValue) {
			case (.Some,.None):
				return false
			case (.None,.Some):
				return false
			case let (.Some(left),.Some(right)):
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
