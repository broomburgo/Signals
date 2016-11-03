public protocol HomomorphismType {
	associatedtype SourceType
	associatedtype TargetType

	func direct(_ value: SourceType) -> TargetType
}

public struct Homomorphism<Source,Target>: HomomorphismType {
	public typealias SourceType = Source
	public typealias TargetType = Target

	fileprivate let directFunction: (SourceType) -> TargetType
	public init(_ directFunction: @escaping (SourceType) -> TargetType) {
		self.directFunction = directFunction
	}

	/// HomomorphismType
	public func direct(_ value: SourceType) -> TargetType {
		return directFunction(value)
	}
}

public typealias Hom<A,B> = Homomorphism<A,B>

public protocol EndomorphismType: HomomorphismType {}

extension EndomorphismType {
	public typealias TargetType = SourceType
}

public struct Endomorphism<Source>: EndomorphismType, Monoid {
	public typealias SourceType = Source

	let directFunction: (Source) -> Source
	public init(_ directFunction: @escaping (Source) -> Source) {
		self.directFunction = directFunction
	}

	/// HomomorphismType
	public func direct(_ value: Source) -> Source {
		return directFunction(value)
	}

	/// Monoid
	public static var empty: Endomorphism {
		return Endomorphism { $0 }
	}

	public func compose(_ other: Endomorphism) -> Endomorphism {
		return Endomorphism { other.direct(self.direct($0)) }
	}

	/// Utility
	public static var identity: Endomorphism {
		return Endomorphism { $0 }
	}

	public func andThen(_ other: Endomorphism) -> Endomorphism {
		return Endomorphism { other.direct(self.direct($0)) }
	}
}

public typealias Endo<A> = Endomorphism<A>

public protocol IsomorphismType: HomomorphismType {
	func inverse(_ value: TargetType) -> SourceType
}

public struct Isomorphism<Source,Target> {
	let directFunction: (Source) -> Target
	let inverseFunction: (Target) -> Source

	public init(directFunction: @escaping (Source) -> Target, inverseFunction: @escaping (Target) -> Source) {
		self.directFunction = directFunction
		self.inverseFunction = inverseFunction
	}

	/// HomomorphismType
	public func direct(_ value: Source) -> Target {
		return directFunction(value)
	}

	/// IsomorphismType
	public func inverse(_ value: Target) -> Source {
		return inverseFunction(value)
	}
}

public typealias Iso<A,B> = Isomorphism<A,B>

public protocol AutomorphismType: EndomorphismType, IsomorphismType {}

public struct Automorphism<Source>: AutomorphismType, Monoid {
	let directFunction: (Source) -> Source
	let inverseFunction: (Source) -> Source

	public init(directFunction: @escaping (Source) -> Source, inverseFunction: @escaping (Source) -> Source) {
		self.directFunction = directFunction
		self.inverseFunction = inverseFunction
	}

	/// HomomorphismType
	public func direct(_ value: Source) -> Source {
		return directFunction(value)
	}

	/// IsomorphismType
	public func inverse(_ value: Source) -> Source {
		return inverseFunction(value)
	}

	/// Monoid
	public static var empty: Automorphism {
		return Automorphism(directFunction: { $0 }, inverseFunction: { $0 })
	}

	public func compose(_ other: Automorphism) -> Automorphism {
		return Automorphism(
			directFunction: { other.direct(self.direct($0)) },
			inverseFunction: { self.inverse(other.inverse($0)) })
	}
}

public typealias Auto<A> = Automorphism<A>
