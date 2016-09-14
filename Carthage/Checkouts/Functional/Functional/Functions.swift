public func ignoreInput<A,B>(_ function: @escaping () -> B) -> (A) -> B {
	return { _ in
		let b = function()
		return b
	}
}

public func ignoreOutput<A,B>(_ function: @escaping (A) -> B) -> (A) -> () {
	return { a in
		_ = function(a)
		return
	}
}

public func compose <A, B, C> (_ first: @escaping (A) -> B, _ second: @escaping (B) -> C) -> (A) -> C {
	return { second(first($0)) }
}

public func identity<A>(_ value: A) -> A {
	return value
}

