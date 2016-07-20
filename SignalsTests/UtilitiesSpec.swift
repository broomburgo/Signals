import XCTest
@testable import Signals

class UtilitiesSpec: XCTestCase {

	func testAlways() {
		let function: Int -> () = { _ in }
		let alwaysFunction = always(function)

		XCTAssertEqual(alwaysFunction(42), SignalPersistence.Continue)
		XCTAssertEqual(alwaysFunction(2), SignalPersistence.Continue)
		XCTAssertEqual(alwaysFunction(-100), SignalPersistence.Continue)
		XCTAssertEqual(alwaysFunction(0), SignalPersistence.Continue)
		XCTAssertEqual(alwaysFunction(Int.max), SignalPersistence.Continue)
		XCTAssertEqual(alwaysFunction(Int.min), SignalPersistence.Continue)
	}

	func testOnce() {
		let function: Int -> () = { _ in }
		let onceFunction = once(function)

		XCTAssertEqual(onceFunction(42), SignalPersistence.Stop)
		XCTAssertEqual(onceFunction(2), SignalPersistence.Stop)
		XCTAssertEqual(onceFunction(-100), SignalPersistence.Stop)
		XCTAssertEqual(onceFunction(0), SignalPersistence.Stop)
		XCTAssertEqual(onceFunction(Int.max), SignalPersistence.Stop)
		XCTAssertEqual(onceFunction(Int.min), SignalPersistence.Stop)
	}
}
