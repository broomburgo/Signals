import XCTest
@testable import Signals

class SignalsSpec: XCTestCase {

	func testEmitterSendSingle() {
		let emitter = Emitter<Int>()

		let expectedValue1 = 42
		let willObserve1 = expectation(description: "willObserve1")

		emitter.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .again
		}

		emitter.update(expectedValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testEmitterSendMultiple() {
		let emitter = Emitter<Int>()

		let expectedValue1 = 42
		let expectedValue2 = 43
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		var observedOnce = false

		emitter.onNext { value in
			if observedOnce {
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .again
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .again
			}
		}

		emitter.update(expectedValue1)
		emitter.update(expectedValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testEmitterStop() {
		let emitter = Emitter<Int>()

		let expectedValue1 = 42
		let unexpectedValue2 = 43
		let unexpectedValue3 = 44
		let unexpectedValue4 = 45
		let unexpectedValue5 = 46
		let willObserve1 = expectation(description: "willObserve1")

		var observedOnce = false

		emitter.onNext { value in
			if observedOnce {
				fatalError()
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .stop
			}
		}

		emitter.update(expectedValue1)
		emitter.update(unexpectedValue2)
		emitter.update(unexpectedValue3)
		emitter.update(unexpectedValue4)
		emitter.update(unexpectedValue5)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFulfilled() {

		let fulfilled = Fulfilled(42)

		let willObserve1 = expectation(description: "willObserve1")
		fulfilled.onNext {
			XCTAssertEqual($0, 42)
			willObserve1.fulfill()
			return .stop
		}

		let willObserve2 = expectation(description: "willObserve2")
		fulfilled.onNext {
			XCTAssertEqual($0, 42)
			willObserve2.fulfill()
			return .stop
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
