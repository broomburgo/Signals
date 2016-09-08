public func ignoreInput<A,B>(function: () -> B) -> A -> B {
	return { _ in
		let b = function()
		return b
	}
}

public func ignoreOutput<A,B>(function: A -> B) -> A -> () {
	return { a in
		function(a)
		return
	}
}

public func compose <A, B, C> (first: A -> B, _ second: B -> C) -> A -> C {
	return { second(first($0)) }
}

public func identity<A>(value: A) -> A {
	return value
}

