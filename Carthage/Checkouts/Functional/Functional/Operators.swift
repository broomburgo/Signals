infix operator • { associativity left precedence 110 }

public func • <A, B, C> (left: B -> C, right: A -> B) -> A -> C {
	return { left(right($0)) }
}

infix operator |> { associativity left precedence 95 }

public func |> <A, B> (left: A, @noescape right: A throws -> B) rethrows -> B {
	return try right(left)
}

infix operator >>> { associativity left precedence 110 }

public func >>> <A, B, C> (left: A -> B, right: B -> C) -> A -> C {
	return { right(left($0)) }
}

public struct Use<A,B,C> {
	let function: A -> B -> C
	public init(_ function: A -> B -> C) {
		self.function = function
	}

	public func with(value: B) -> A -> C {
		return { a in
			self.function(a)(value)
		}
	}
}
