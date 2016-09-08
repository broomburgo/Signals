extension Array {
	public var head: Element? {
		return first
	}

	public var tail: [Element]? {
		guard count > 0 else { return nil }
		guard count > 1 else { return [] }
		return Array(self[1..<count])
	}

	public func extended(with value: Element) -> Array {
		var m_self = self
		m_self.append(value)
		return m_self
	}

	public func find(@noescape predicate: Element -> Bool) -> Element? {
		for element in self {
			if predicate(element) { return element }
		}
		return nil
	}

	public func mapSome<Other>(@noescape transform: Element -> Other?) -> [Other] {
		return flatMap(transform)
	}

	public func accumulate(@noescape combine: (Element, Element) throws -> Element) rethrows -> Element? {
		guard let head = head, let tail = tail else { return first }
		return try tail.reduce(head, combine: combine)
	}

	public func isEqual(to other: [Element], considering predicate: (Element,Element) -> Bool) -> Bool {
		guard count == other.count else { return false }
		for (index,element) in enumerate() {
			if predicate(element,other[index]) == false {
				return false
			}
		}
		return true
	}
}

extension Array where Element: Equatable {
	public func isEqual(to other: [Element]) -> Bool {
		return isEqual(to: other, considering: ==)
	}
}

extension Array where Element: Monoid {
	public func composeAll() -> Element {
		return accumulate { $0.compose($1) } ?? Element.empty
	}

	public func composeAll(joinedBy element: Element) -> Element {
		return accumulate { $0.compose(element).compose($1) } ?? Element.empty
	}
}

