import XCTest
@testable import Signals

class ProtocolsSpec: XCTestCase {

	func testBindSignalToSignal() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<Int>()

		signal2.bind(to: signal1.map { $0*2 })

		let sentValue = 42
		let expectedValue = 84

		let willObserve = expectation(description: "willObserve")

		signal2.onNext { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			return .continue
		}

		signal1.send(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}
}
