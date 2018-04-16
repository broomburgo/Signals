import XCTest
import Signals

class BindingSpec: XCTestCase {

	func testBindEmitterToEmitter() {
		let emitter = Emitter<Int>()
		let bound = Emitter<Int>()
		let sendDisconnect = Emitter<()>()

		let binding = emitter.map { $0*2 }.bind(to: bound)

		let sentValue = 42
		let expectedValue = 84

		let willObserve1 = expectation(description: "willObserve1")

		bound.onNext { value in
			willObserve1.fulfill()
			XCTAssertEqual(value, expectedValue)
			sendDisconnect.update(())
			return .again
		}

		let willObserve2 = expectation(description: "willObserve2")

		sendDisconnect.onNext {
			willObserve2.fulfill()
			binding.dispose()
			emitter.update(sentValue)
			emitter.update(sentValue)
			return .stop
		}

		emitter.update(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
