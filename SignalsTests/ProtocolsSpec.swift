import XCTest
@testable import Signals

class ProtocolsSpec: XCTestCase {

	func testBindEmitterToEmitter() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let binding = Binding(observable: emitter1.map { $0*2 }, variable: emitter2)

		let sentValue = 42
		let expectedValue = 84

		let willObserve = expectation(description: "willObserve")

		emitter2.onNext { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			binding.disconnect()
			return .again
		}

		emitter1.update(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

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
