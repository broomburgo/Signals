import XCTest
import SwiftCheck

@testable import Functional

extension Optional where Wrapped: Equatable {
	func isEqualTo(other: Optional<Wrapped>) -> Bool {
		switch (self,other) {
		case let (.Some(rightValue),.Some(leftValue)):
			return rightValue == leftValue
		case (.None,.None):
			return true
		default:
			return false
		}
	}

	static func firstLaw(f f: Wrapped -> Optional<Wrapped>) -> Wrapped -> Bool {
		return { x in (Optional(x).flatMap(f)).isEqualTo(f(x)) }
	}

	static func secondLaw() -> Wrapped -> Bool {
		return { x in (Optional(x).flatMap(Optional.init)).isEqualTo(Optional(x)) }
	}

	static func thirdLaw(f f: Wrapped -> Optional<Wrapped>, g: Wrapped -> Optional<Wrapped>) -> Wrapped -> Bool {
		return { x in (Optional(x).flatMap(f).flatMap(g)).isEqualTo(Optional(x).flatMap { a in f(a).flatMap(g) }) }
	}
}

class OptionalSpec: XCTestCase {
	func testFunctorLaws() {
		property("map(identity) ≡ identity") <- forAll { (arbitraryOptional: OptionalOf<Int>) in
			let either = arbitraryOptional.getOptional
			let mapId: Optional<Int> -> Optional<Int> = Use(Optional.map).with(identity)
			return mapId(either).isEqualTo(identity(either))
		}

		property("map(g•f) ≡ map(g) • map(f)") <- forAll { (arbitraryOptional: OptionalOf<Int>, fArrow: ArrowOf<Int,Bool>, gArrow: ArrowOf<Bool,String>) in
			let f = fArrow.getArrow
			let g = gArrow.getArrow
			let h = compose(f,g)
			let mapH: Optional<Int> -> Optional<String> = Use(Optional.map).with(h)
			let mapF: Optional<Int> -> Optional<Bool> = Use(Optional.map).with(f)
			let mapG: Optional<Bool> -> Optional<String> = Use(Optional.map).with(g)
			let mapGF = compose(mapF,mapG)
			return mapH(arbitraryOptional.getOptional).isEqualTo(mapGF(arbitraryOptional.getOptional))
		}
	}

	func testMonadLaws() {
		property("Either(x).flatMap(f) ≡ f(x)") <- forAll { (value: Int, fArrow: ArrowOf<Int,OptionalOf<Int>>) in
			value |> Optional<Int>.firstLaw(f: { x in fArrow.getArrow(x).getOptional })
		}

		property("Either(x).flatMap(Either.init) ≡ Either(x)")  <- forAll { (value: Int) in
			value |> Optional<Int>.secondLaw()
		}

		property("Either(x).flatMap(f).flatMap(g) ≡ Either(x).flatMap { x in f(x).flatMap(g) }") <- forAll { (value: Int, fArrow: ArrowOf<Int,OptionalOf<Int>>, gArrow: ArrowOf<Int,OptionalOf<Int>>) in
			value |> Optional<Int>.thirdLaw(f: { x in fArrow.getArrow(x).getOptional }, g: { x in gArrow.getArrow(x).getOptional })
		}
	}
}
