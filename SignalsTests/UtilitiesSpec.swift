import XCTest
@testable import Signals

class UtilitiesSpec: XCTestCase {

	func testAlways() {
		let function: (Int) -> () = { _ in }
		let alwaysFunction = always(function)

		XCTAssertEqual(alwaysFunction(42), Persistence.again)
		XCTAssertEqual(alwaysFunction(2), Persistence.again)
		XCTAssertEqual(alwaysFunction(-100), Persistence.again)
		XCTAssertEqual(alwaysFunction(0), Persistence.again)
		XCTAssertEqual(alwaysFunction(Int.max), Persistence.again)
		XCTAssertEqual(alwaysFunction(Int.min), Persistence.again)
	}

	func testOnce() {
		let function: (Int) -> () = { _ in }
		let onceFunction = once(function)

		XCTAssertEqual(onceFunction(42), Persistence.stop)
		XCTAssertEqual(onceFunction(2), Persistence.stop)
		XCTAssertEqual(onceFunction(-100), Persistence.stop)
		XCTAssertEqual(onceFunction(0), Persistence.stop)
		XCTAssertEqual(onceFunction(Int.max), Persistence.stop)
		XCTAssertEqual(onceFunction(Int.min), Persistence.stop)
	}

	func testWhileTrueFixed() {
		let box = Box<Bool>(value: true)

		let function: (Int) -> () = { _ in }
		let whileTrueFunction = whileTrue { _ in box.value } (function)

		XCTAssertEqual(whileTrueFunction(42), Persistence.again)
		XCTAssertEqual(whileTrueFunction(2), Persistence.again)
		XCTAssertEqual(whileTrueFunction(-100), Persistence.again)
		box.value = false
		XCTAssertEqual(whileTrueFunction(0), Persistence.stop)
		XCTAssertEqual(whileTrueFunction(Int.max), Persistence.stop)
		XCTAssertEqual(whileTrueFunction(Int.min), Persistence.stop)
	}

	func testWhileTrueDependent() {
		let function: (Int) -> () = { _ in }
		let whileTrueFunction = whileTrue { $0%2 == 0 } (function)

		XCTAssertEqual(whileTrueFunction(1), Persistence.stop)
		XCTAssertEqual(whileTrueFunction(2), Persistence.again)
		XCTAssertEqual(whileTrueFunction(3), Persistence.stop)
		XCTAssertEqual(whileTrueFunction(4), Persistence.again)
		XCTAssertEqual(whileTrueFunction(5), Persistence.stop)
		XCTAssertEqual(whileTrueFunction(6), Persistence.again)
	}
}
