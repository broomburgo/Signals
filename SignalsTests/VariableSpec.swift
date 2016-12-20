import XCTest
@testable import Signals

class SignalsSpec: XCTestCase {

	func testVariableSendSingle() {
		let variable = Variable<Int>()

		let expectedValue1 = 42
		let willObserve1 = expectation(description: "willObserve1")

		variable.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .again
		}

		variable.update(expectedValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testVariableSendMultiple() {
		let variable = Variable<Int>()

		let expectedValue1 = 42
		let expectedValue2 = 43
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		var observedOnce = false

		variable.onNext { value in
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

		variable.update(expectedValue1)
		variable.update(expectedValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testVariableStop() {
		let variable = Variable<Int>()

		let expectedValue1 = 42
		let unexpectedValue2 = 43
		let unexpectedValue3 = 44
		let unexpectedValue4 = 45
		let unexpectedValue5 = 46
		let willObserve1 = expectation(description: "willObserve1")

		var observedOnce = false

		variable.onNext { value in
			if observedOnce {
				fatalError()
			} else {
				observedOnce = true
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .stop
			}
		}

		variable.update(expectedValue1)
		variable.update(unexpectedValue2)
		variable.update(unexpectedValue3)
		variable.update(unexpectedValue4)
		variable.update(unexpectedValue5)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
