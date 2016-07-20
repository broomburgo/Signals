import XCTest
@testable import Signals

class ProtocolsSpec: XCTestCase {

	func testDeferredObservable() {
		let deferred = FillableDeferred<Int>()

		let expectedValue = 42
		let unexpectedValue = 42

		let willObserve = expectationWithDescription("willObserve")

		deferred.observable().observe { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			return .Continue
		}

		deferred.fill(expectedValue)
		deferred.fill(unexpectedValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testChainedDeferredObservable() {
		let baseDeferred = FillableDeferred<Int>()
		let deferred = Deferred(value: nil, observable: baseDeferred
			.observable()
			.single()
			.observable()
			.single()
			.observable())


		let expectedValue = 42
		let unexpectedValue = 42

		let willObserve = expectationWithDescription("willObserve")

		deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
		}
		
		baseDeferred.fill(expectedValue)
		baseDeferred.fill(unexpectedValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testBindSignalToSignal() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<Int>()

		signal2.bind(to: signal1.map { $0*2 })

		let sentValue = 42
		let expectedValue = 84

		let willObserve = expectationWithDescription("willObserve")

		signal2.observe { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			return .Continue
		}

		signal1.send(sentValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testBindSignalToDeferred() {
		let deferred = FillableDeferred<Int>()
		let signal = Signal<Int>()

		signal.bind(to: deferred.map { $0*2 })

		let sentValue = 42
		let expectedValue = 84

		let willObserve = expectationWithDescription("willObserve")

		signal.observe { value in
			XCTAssertEqual(value, expectedValue)
			willObserve.fulfill()
			return .Continue
		}

		deferred.fill(sentValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

}
