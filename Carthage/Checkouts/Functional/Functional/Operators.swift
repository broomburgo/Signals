infix operator • : MultiplicationPrecedence

public func • <A, B, C> (left: @escaping (B) -> C, right: @escaping (A) -> B) -> (A) -> C {
	return { left(right($0)) }
}

infix operator |> : MultiplicationPrecedence

public func |> <A, B> (left: A, right: (A) throws -> B) rethrows -> B {
	return try right(left)
}

infix operator >>> : MultiplicationPrecedence

public func >>> <A, B, C> (left: @escaping (A) -> B, right: @escaping (B) -> C) -> (A) -> C {
	return { right(left($0)) }
}

public struct Use<A,B,C> {
	let function: (A) -> (B) -> C
	public init(_ function: @escaping (A) -> (B) -> C) {
		self.function = function
	}

	public func with(_ value: B) -> (A) -> C {
		return { a in
			self.function(a)(value)
		}
	}
}
