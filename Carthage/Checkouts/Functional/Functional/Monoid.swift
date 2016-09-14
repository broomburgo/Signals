import Foundation

public protocol Semigroup {
	/// AXIOM: is associative
	/// a.compose(b.compose(c)) = (a.compose(b)).compose(c)
	func compose(_ other: Self) -> Self
}

public protocol EmptyType {
	static var empty: Self { get }
}

public protocol Monoid: Semigroup, EmptyType {
	/// AXIOM: Self.empty <> a == a <> Self.empty == a
}

public protocol InverseType {
	var inverse: Self { get }
}

extension Bool: InverseType {
	public var inverse: Bool {
		return self == false
	}
}

public protocol Group: Monoid, InverseType {
	/// AXIOM: a <> a.inverse == a.inverse <> a == Self.empty
}
