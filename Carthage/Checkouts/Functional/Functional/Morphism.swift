public protocol HomomorphismType {
	associatedtype SourceType
	associatedtype TargetType

	func direct(value: SourceType) -> TargetType
}

public struct Homomorphism<Source,Target>: HomomorphismType {
	public typealias SourceType = Source
	public typealias TargetType = Target

	private let directFunction: SourceType -> TargetType
	public init(_ directFunction: SourceType -> TargetType) {
		self.directFunction = directFunction
	}

	/// HomomorphismType
	public func direct(value: SourceType) -> TargetType {
		return directFunction(value)
	}
}

public protocol EndomorphismType: HomomorphismType {}

extension EndomorphismType {
	public typealias TargetType = SourceType
}

public struct Endomorphism<Source>: EndomorphismType, Monoid {
	public typealias SourceType = Source

	let directFunction: Source -> Source
	public init(_ directFunction: Source -> Source) {
		self.directFunction = directFunction
	}

	/// HomomorphismType
	public func direct(value: Source) -> Source {
		return directFunction(value)
	}

	/// Monoid
	public static var empty: Endomorphism {
		return Endomorphism { $0 }
	}

	public func compose(other: Endomorphism) -> Endomorphism {
		return Endomorphism { other.direct(self.direct($0)) }
	}

	/// Utility
	public static var identity: Endomorphism {
		return Endomorphism { $0 }
	}

	public func andThen(other: Endomorphism) -> Endomorphism {
		return Endomorphism { other.direct(self.direct($0)) }
	}
}

public protocol IsomorphismType: HomomorphismType {
	func inverse(value: TargetType) -> SourceType
}

public struct Isomorphism<Source,Target> {
	let directFunction: Source -> Target
	let inverseFunction: Target -> Source

	public init(directFunction: Source -> Target, inverseFunction: Target -> Source) {
		self.directFunction = directFunction
		self.inverseFunction = inverseFunction
	}

	/// HomomorphismType
	public func direct(value: Source) -> Target {
		return directFunction(value)
	}

	/// IsomorphismType
	public func inverse(value: Target) -> Source {
		return inverseFunction(value)
	}
}

public protocol AutomorphismType: EndomorphismType, IsomorphismType {}

public struct Automorphism<Source>: AutomorphismType, Monoid {
	let directFunction: Source -> Source
	let inverseFunction: Source -> Source

	public init(directFunction: Source -> Source, inverseFunction: Source -> Source) {
		self.directFunction = directFunction
		self.inverseFunction = inverseFunction
	}

	/// HomomorphismType
	public func direct(value: Source) -> Source {
		return directFunction(value)
	}

	/// IsomorphismType
	public func inverse(value: Source) -> Source {
		return inverseFunction(value)
	}

	/// Monoid
	public static var empty: Automorphism {
		return Automorphism(directFunction: { $0 }, inverseFunction: { $0 })
	}

	public func compose(other: Automorphism) -> Automorphism {
		return Automorphism(
			directFunction: { other.direct(self.direct($0)) },
			inverseFunction: { self.inverse(other.inverse($0)) })
	}
}
