import XCTest
import Signals

class ProtocolsSpec: XCTestCase {

	func testSingle() {
		let emitter = Emitter<Int>()
		let single = emitter.single

		let expectedValue1 = 42
		let expectedValue2 = 43
		let expectedValue3 = 44
		let willObserve1 = expectation(description: "willObserve1")

		single.upon { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
		}

		emitter.update(expectedValue1)
		emitter.update(expectedValue2)
		emitter.update(expectedValue3)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
