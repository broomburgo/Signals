public struct Curried1<A,B>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = B

	let function: ((A) -> B)
	public init(_ function: @escaping ((A) -> B)) {
		self.function = function
	}

	public func direct(_ value: A) -> B {
		return function(value)
	}
}

public struct Curried2<A,B,C>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried1<B,C>

	let function: ((A,B) -> C)
	public init(_ function: @escaping ((A,B) -> C)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried1<B,C> {
		return Curried1 { b in
			self.function(value,b)
		}
	}
}

public struct Curried3<A,B,C,D>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried2<B,C,D>

	let function: ((A,B,C) -> D)
	public init(_ function: @escaping ((A,B,C) -> D)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried2<B,C,D> {
		return Curried2 { (c,d) in
			self.function(value,c,d)
		}
	}
}

public struct Curried4<A,B,C,D,E>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried3<B,C,D,E>

	let function: ((A,B,C,D) -> E)
	public init(_ function: @escaping ((A,B,C,D) -> E)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried3<B,C,D,E> {
		return Curried3 { (c,d,e) in
			self.function(value,c,d,e)
		}
	}
}

public struct Curried5<A,B,C,D,E,F>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried4<B,C,D,E,F>

	let function: ((A,B,C,D,E) -> F)
	public init(_ function: @escaping ((A,B,C,D,E) -> F)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried4<B,C,D,E,F> {
		return Curried4 { (c,d,e,f) in
			self.function(value,c,d,e,f)
		}
	}
}

public struct Curried6<A,B,C,D,E,F,G>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried5<B,C,D,E,F,G>

	let function: ((A,B,C,D,E,F) -> G)
	public init(_ function: @escaping ((A,B,C,D,E,F) -> G)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried5<B,C,D,E,F,G> {
		return Curried5 { (c,d,e,f,g) in
			self.function(value,c,d,e,f,g)
		}
	}
}

public struct Curried7<A,B,C,D,E,F,G,H>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried6<B,C,D,E,F,G,H>

	let function: ((A,B,C,D,E,F,G) -> H)
	public init(_ function: @escaping ((A,B,C,D,E,F,G) -> H)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried6<B,C,D,E,F,G,H> {
		return Curried6 { (c,d,e,f,g,h) in
			self.function(value,c,d,e,f,g,h)
		}
	}
}

public struct Curried8<A,B,C,D,E,F,G,H,I>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried7<B,C,D,E,F,G,H,I>

	let function: ((A,B,C,D,E,F,G,H) -> I)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H) -> I)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried7<B,C,D,E,F,G,H,I> {
		return Curried7 { (c,d,e,f,g,h,i) in
			self.function(value,c,d,e,f,g,h,i)
		}
	}
}

public struct Curried9<A,B,C,D,E,F,G,H,I,J>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried8<B,C,D,E,F,G,H,I,J>

	let function: ((A,B,C,D,E,F,G,H,I) -> J)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I) -> J)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried8<B,C,D,E,F,G,H,I,J> {
		return Curried8 { (c,d,e,f,g,h,i,j) in
			self.function(value,c,d,e,f,g,h,i,j)
		}
	}
}

public struct Curried10<A,B,C,D,E,F,G,H,I,J,K>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried9<B,C,D,E,F,G,H,I,J,K>

	let function: ((A,B,C,D,E,F,G,H,I,J) -> K)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I,J) -> K)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried9<B,C,D,E,F,G,H,I,J,K> {
		return Curried9 { (c,d,e,f,g,h,i,j,k) in
			self.function(value,c,d,e,f,g,h,i,j,k)
		}
	}
}

public struct Curried11<A,B,C,D,E,F,G,H,I,J,K,L>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried10<B,C,D,E,F,G,H,I,J,K,L>

	let function: ((A,B,C,D,E,F,G,H,I,J,K) -> L)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I,J,K) -> L)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried10<B,C,D,E,F,G,H,I,J,K,L> {
		return Curried10 { (c,d,e,f,g,h,i,j,k,l) in
			self.function(value,c,d,e,f,g,h,i,j,k,l)
		}
	}
}

public struct Curried12<A,B,C,D,E,F,G,H,I,J,K,L,M>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried11<B,C,D,E,F,G,H,I,J,K,L,M>

	let function: ((A,B,C,D,E,F,G,H,I,J,K,L) -> M)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I,J,K,L) -> M)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried11<B,C,D,E,F,G,H,I,J,K,L,M> {
		return Curried11 { (c,d,e,f,g,h,i,j,k,l,m) in
			self.function(value,c,d,e,f,g,h,i,j,k,l,m)
		}
	}
}

public struct Curried13<A,B,C,D,E,F,G,H,I,J,K,L,M,N>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried12<B,C,D,E,F,G,H,I,J,K,L,M,N>

	let function: ((A,B,C,D,E,F,G,H,I,J,K,L,M) -> N)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I,J,K,L,M) -> N)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried12<B,C,D,E,F,G,H,I,J,K,L,M,N> {
		return Curried12 { (c,d,e,f,g,h,i,j,k,l,m,n) in
			self.function(value,c,d,e,f,g,h,i,j,k,l,m,n)
		}
	}
}

public struct Curried14<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O>: HomomorphismType {
	public typealias SourceType = A
	public typealias TargetType = Curried13<B,C,D,E,F,G,H,I,J,K,L,M,N,O>

	let function: ((A,B,C,D,E,F,G,H,I,J,K,L,M,N) -> O)
	public init(_ function: @escaping ((A,B,C,D,E,F,G,H,I,J,K,L,M,N) -> O)) {
		self.function = function
	}

	public func direct(_ value: A) -> Curried13<B,C,D,E,F,G,H,I,J,K,L,M,N,O> {
		return Curried13 { (c,d,e,f,g,h,i,j,k,l,m,n,o) in
			self.function(value,c,d,e,f,g,h,i,j,k,l,m,n,o)
		}
	}
}

public func curried<A, B, C>(_ function: @escaping (A, B) -> C) -> Curried2<A,B,C> {
	return Curried2(function)
}

public func curried<A, B, C, D>(_ function: @escaping (A, B, C) -> D) -> Curried3<A,B,C,D> {
	return Curried3(function)
}

public func curried<A, B, C, D, E>(_ function: @escaping (A, B, C, D) -> E) -> Curried4<A,B,C,D,E> {
	return Curried4(function)
}

public func curried<A, B, C, D, E, F>(_ function: @escaping (A, B, C, D, E) -> F) -> Curried5<A,B,C,D,E,F> {
	return Curried5(function)
}

public func curried<A, B, C, D, E, F, G>(_ function: @escaping (A, B, C, D, E, F) -> G) -> Curried6<A,B,C,D,E,F,G> {
	return Curried6(function)
}

public func curried<A, B, C, D, E, F, G, H>(_ function: @escaping (A, B, C, D, E, F, G) -> H) -> Curried7<A,B,C,D,E,F,G,H> {
	return Curried7(function)
}

public func curried<A, B, C, D, E, F, G, H, I>(_ function: @escaping (A, B, C, D, E, F, G, H) -> I) -> Curried8<A,B,C,D,E,F,G,H,I> {
	return Curried8(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J>(_ function: @escaping (A, B, C, D, E, F, G, H, I) -> J) -> Curried9<A,B,C,D,E,F,G,H,I,J> {
	return Curried9(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J, K>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J) -> K) -> Curried10<A,B,C,D,E,F,G,H,I,J,K> {
	return Curried10(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J, K, L>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K) -> L) -> Curried11<A,B,C,D,E,F,G,H,I,J,K,L> {
	return Curried11(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J, K, L, M>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K, L) -> M) -> Curried12<A,B,C,D,E,F,G,H,I,J,K,L,M> {
	return Curried12(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J, K, L, M, N>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M) -> N) -> Curried13<A,B,C,D,E,F,G,H,I,J,K,L,M,N> {
	return Curried13(function)
}

public func curried<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>(_ function: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M, N) -> O) -> Curried14<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O> {
	return Curried14(function)
}
