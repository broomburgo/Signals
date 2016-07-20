import XCTest
@testable import Signals

class SignalsSpec: XCTestCase {

	func testSignalSendSingle() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let willObserve1 = expectationWithDescription("willObserve1")

		signal.observe { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .Continue
		}

		signal.send(expectedValue1)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testSignalSendMultiple() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let expectedValue2 = 43
		let willObserve1 = expectationWithDescription("willObserve1")
		let willObserve2 = expectationWithDescription("willObserve2")

		var observedOnce = false

		signal.observe { value in
			if observedOnce {
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .Continue
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .Continue
			}
		}

		signal.send(expectedValue1)
		signal.send(expectedValue2)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testSignalStop() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let unexpectedValue2 = 43
		let unexpectedValue3 = 44
		let unexpectedValue4 = 45
		let unexpectedValue5 = 46
		let willObserve1 = expectationWithDescription("willObserve1")

		var observedOnce = false

		signal.observe { value in
			if observedOnce {
				fatalError()
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .Stop
			}
		}

		signal.send(expectedValue1)
		signal.send(unexpectedValue2)
		signal.send(unexpectedValue3)
		signal.send(unexpectedValue4)
		signal.send(unexpectedValue5)

		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
