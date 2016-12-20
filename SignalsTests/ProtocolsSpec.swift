import XCTest
@testable import Signals

class ProtocolsSpec: XCTestCase {

	func testBindVariableToVariable() {
		let variable1 = Variable<Int>()
		let variable2 = Variable<Int>()

		variable2.bind(to: variable1.map { $0*2 })

		let sentValue = 42
		let expectedValue = 84

		let willObserve = expectation(description: "willObserve")

		variable2.onNext { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			return .again
		}

		variable1.update(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testSingle() {
		let variable = Variable<Int>()
		let single = variable.single

		let expectedValue1 = 42
		let expectedValue2 = 43
		let expectedValue3 = 44
		let willObserve1 = expectation(description: "willObserve1")

		single.upon { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
		}

		variable.update(expectedValue1)
		variable.update(expectedValue2)
		variable.update(expectedValue3)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
