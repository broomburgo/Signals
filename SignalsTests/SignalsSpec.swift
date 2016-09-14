import XCTest
@testable import Signals

class SignalsSpec: XCTestCase {

	func testSignalSendSingle() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let willObserve1 = expectation(description: "willObserve1")

		_ = signal.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .continue
		}

		_ = signal.send(expectedValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSignalSendMultiple() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let expectedValue2 = 43
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		var observedOnce = false

		_ = signal.onNext { value in
			if observedOnce {
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .continue
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .continue
			}
		}

		_ = signal.send(expectedValue1)
		_ = signal.send(expectedValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSignalStop() {
		let signal = Signal<Int>()

		let expectedValue1 = 42
		let unexpectedValue2 = 43
		let unexpectedValue3 = 44
		let unexpectedValue4 = 45
		let unexpectedValue5 = 46
		let willObserve1 = expectation(description: "willObserve1")

		var observedOnce = false

		_ = signal.onNext { value in
			if observedOnce {
				fatalError()
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .stop
			}
		}

		_ = signal.send(expectedValue1)
		_ = signal.send(unexpectedValue2)
		_ = signal.send(unexpectedValue3)
		_ = signal.send(unexpectedValue4)
		_ = signal.send(unexpectedValue5)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
