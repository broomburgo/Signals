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
}
