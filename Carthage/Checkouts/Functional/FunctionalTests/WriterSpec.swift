import XCTest
import SwiftCheck
@testable import Functional

extension Writer where Wrapped: Equatable, Log: Equatable {
	func isEqualTo(other: Writer<Wrapped,Log>) -> Bool {
		return self.runWriter == other.runWriter
	}

	static func firstLaw(f f: Wrapped -> Writer<Wrapped,Log>) -> Wrapped -> Bool {
		return { x in (Writer(x).flatMap(f)).isEqualTo(f(x)) }
	}

	static func secondLaw() -> Wrapped -> Bool {
		return { x in (Writer(x).flatMap(Writer.init)).isEqualTo(Writer(x)) }
	}

	static func thirdLaw(f f: Wrapped -> Writer<Wrapped,Log>, g: Wrapped -> Writer<Wrapped,Log>) -> Wrapped -> Bool {
		return { x in (Writer(x).flatMap(f).flatMap(g)).isEqualTo(Writer(x).flatMap { a in f(a).flatMap(g) }) }
	}
}

struct ArbitraryWriter: Arbitrary {
	let writer: Writer<Int,String>
	init(writer: Writer<Int,String>) {
		self.writer = writer
	}

	func getWriter() -> Writer<Int,String> {
		return writer
	}

	static var arbitrary: Gen<ArbitraryWriter> {
		return Gen<ArbitraryWriter>.zip(Int.arbitrary, String.arbitrary)
			.map(Writer<Int,String>.init)
			.map(ArbitraryWriter.init)
	}
}

class WriterSpec: XCTestCase {

	func testFunctorLaws() {
		property("map(identity) ≡ identity") <- forAll { (arbitraryWriter: ArbitraryWriter) in
			let writer = arbitraryWriter.getWriter()
			let mapId: Writer<Int,String> -> Writer<Int,String> = Use(Writer.map).with(identity)
			return mapId(writer).isEqualTo(identity(writer))
		}

		property("map(g•f) ≡ map(g) • map(f)") <- forAll { (arbitraryWriter: ArbitraryWriter, fArrow: ArrowOf<Int,Bool>, gArrow: ArrowOf<Bool,String>) in
			let f = fArrow.getArrow
			let g = gArrow.getArrow
			let h = compose(f,g)
			let mapH: Writer<Int,String> -> Writer<String,String> = Use(Writer.map).with(h)
			let mapF: Writer<Int,String> -> Writer<Bool,String> = Use(Writer.map).with(f)
			let mapG: Writer<Bool,String> -> Writer<String,String> = Use(Writer.map).with(g)
			let mapGF = compose(mapF,mapG)
			return mapH(arbitraryWriter.getWriter()).isEqualTo(mapGF(arbitraryWriter.getWriter()))
		}
	}

	func testMonadLaws() {
		property("Writer(x).flatMap(f) ≡ f(x)") <- forAll { (value: Int, fArrow: ArrowOf<Int,ArbitraryWriter>) in
			value |> Writer<Int,String>.firstLaw(f: { x in fArrow.getArrow(x).getWriter() })
		}

		property("Writer(x).flatMap(Writer.init) ≡ Writer(x)")  <- forAll { (value: Int) in
			value |> Writer<Int,String>.secondLaw()
		}

		property("Writer(x).flatMap(f).flatMap(g) ≡ Writer(x).flatMap { x in f(x).flatMap(g) }") <- forAll { (value: Int, fArrow: ArrowOf<Int,ArbitraryWriter>, gArrow: ArrowOf<Int,ArbitraryWriter>) in
			value |> Writer<Int,String>.thirdLaw(f: { x in fArrow.getArrow(x).getWriter() }, g: { x in gArrow.getArrow(x).getWriter() })
		}
	}

	func testTell() {
		property("Writer 'tell' should correctly update the Log") <- forAll { (previous: String, next: String) in
			let writer = Writer("", previous).tell(next)
			return writer.runWriter.1 == previous.compose(next)
		}
	}

	func testListen() {
		property("Writer 'listen' should behave") <- forAll { (value: String, log: String) in
			return Writer(value, log).listen().runWriter.0 == (value,log)
		}
	}

	func testCensor() {
		property("Writer 'censor' should correctly update the Log") <- forAll { (previous: String, next: String) in
			let writer = Writer(wrapped: "", logger: previous).censor { _ in next }
			return writer.runWriter.1 == next
		}
	}
}
