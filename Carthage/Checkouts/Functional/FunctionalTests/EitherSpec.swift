import XCTest
import SwiftCheck
@testable import Functional

extension String: Error {}

extension Either where Wrapped: Equatable {
	func isEqualTo(_ other: Either<Wrapped>) -> Bool {
		switch (self,other) {
		case let (.right(rightValue),.right(leftValue)):
			return rightValue == leftValue
		case let (.left(rightError),.left(leftError)):
			guard let
				rightString = rightError as? String,
				let leftString = leftError as? String else { return false }
			return leftString == rightString
		default:
			return false
		}
	}

	static func firstLaw(f: @escaping (Wrapped) -> Either<Wrapped>) -> (Wrapped) -> Bool {
		return { x in (Either(x).flatMap(f)).isEqualTo(f(x)) }
	}

	static func secondLaw() -> (Wrapped) -> Bool {
		return { x in (Either(x).flatMap(Either.init)).isEqualTo(Either(x)) }
	}

	static func thirdLaw(f: @escaping (Wrapped) -> Either<Wrapped>, g: @escaping (Wrapped) -> Either<Wrapped>) -> (Wrapped) -> Bool {
		return { x in (Either(x).flatMap(f).flatMap(g)).isEqualTo(Either(x).flatMap { a in f(a).flatMap(g) }) }
	}
}

struct ArbitraryEither: Arbitrary {
	let either: Either<Int>
	init(either: Either<Int>) {
		self.either = either
	}

	static var arbitrary: Gen<ArbitraryEither> {
		return Gen<ArbitraryEither>.zip(Int.arbitrary, String.arbitrary, Bool.arbitrary)
			.map { (value: Int, error: String, isRight: Bool) -> Either<Int> in
				isRight.analyze(ifTrue: Either.right(value), ifFalse: Either.left(error))
			}
		.map(ArbitraryEither.init)
	}
}

class EitherSpec: XCTestCase {
	func testFunctorLaws() {
		property("map(identity) ≡ identity") <- forAll { (arbitraryEither: ArbitraryEither) in
			let either = arbitraryEither.either
			let mapId: (Either<Int>) -> Either<Int> = Use(Either.map).with(identity)
			return mapId(either).isEqualTo(identity(either))
		}

		property("map(g•f) ≡ map(g) • map(f)") <- forAll { (arbitraryEither: ArbitraryEither, fArrow: ArrowOf<Int,Bool>, gArrow: ArrowOf<Bool,String>) in
			let f = fArrow.getArrow
			let g = gArrow.getArrow
			let h = compose(f,g)
			let mapH: (Either<Int>) -> Either<String> = Use(Either.map).with(h)
			let mapF: (Either<Int>) -> Either<Bool> = Use(Either.map).with(f)
			let mapG: (Either<Bool>) -> Either<String> = Use(Either.map).with(g)
			let mapGF = compose(mapF,mapG)
			return mapH(arbitraryEither.either).isEqualTo(mapGF(arbitraryEither.either))
		}
	}

	func testMonadLaws() {
		property("Either(x).flatMap(f) ≡ f(x)") <- forAll { (value: Int, fArrow: ArrowOf<Int,ArbitraryEither>) in
			value |> Either<Int>.firstLaw(f: { x in fArrow.getArrow(x).either })
		}

		property("Either(x).flatMap(Either.init) ≡ Either(x)")  <- forAll { (value: Int) in
			value |> Either<Int>.secondLaw()
		}

		property("Either(x).flatMap(f).flatMap(g) ≡ Either(x).flatMap { x in f(x).flatMap(g) }") <- forAll { (value: Int, fArrow: ArrowOf<Int,ArbitraryEither>, gArrow: ArrowOf<Int,ArbitraryEither>) in
			value |> Either<Int>.thirdLaw(f: { x in fArrow.getArrow(x).either }, g: { x in gArrow.getArrow(x).either })
		}
	}

	func testGetOrElse() {
		property("Either.getOrElse should work properly") <- forAll { (arbitraryEither: ArbitraryEither, elseValue: Int) in
			let either = arbitraryEither.either
			switch arbitraryEither.either {
			case let .right(value):
				return value == either.getOrElse(elseValue)
			case .left:
				return elseValue == either.getOrElse(elseValue)
			}
		}
	}

	func testSet() {
		property("Either.set should containt the same thrown error") <- forAll { (error: String) in
			func notWorking() throws -> Int {
				throw error
			}
			let expectedEither: Either<Int> = Either(error)
			return Either.set(notWorking).isEqualTo(expectedEither)
		}
	}
}
