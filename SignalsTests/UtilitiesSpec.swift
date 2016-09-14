import XCTest
@testable import Signals

class UtilitiesSpec: XCTestCase {

	func testAlways() {
		let function: (Int) -> () = { _ in }
		let alwaysFunction = always(function)

		XCTAssertEqual(alwaysFunction(42), SignalPersistence.continue)
		XCTAssertEqual(alwaysFunction(2), SignalPersistence.continue)
		XCTAssertEqual(alwaysFunction(-100), SignalPersistence.continue)
		XCTAssertEqual(alwaysFunction(0), SignalPersistence.continue)
		XCTAssertEqual(alwaysFunction(Int.max), SignalPersistence.continue)
		XCTAssertEqual(alwaysFunction(Int.min), SignalPersistence.continue)
	}

	func testOnce() {
		let function: (Int) -> () = { _ in }
		let onceFunction = once(function)

		XCTAssertEqual(onceFunction(42), SignalPersistence.stop)
		XCTAssertEqual(onceFunction(2), SignalPersistence.stop)
		XCTAssertEqual(onceFunction(-100), SignalPersistence.stop)
		XCTAssertEqual(onceFunction(0), SignalPersistence.stop)
		XCTAssertEqual(onceFunction(Int.max), SignalPersistence.stop)
		XCTAssertEqual(onceFunction(Int.min), SignalPersistence.stop)
	}
}
