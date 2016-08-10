import XCTest
import Functional
import SwiftCheck
@testable import Signals

class DeferredSpec: XCTestCase {

	func testInitWithSignal() {
		let signal = Signal<Int>()
		let deferred = Deferred(nil, signal)

		let expectedValue = 42

		let willUpon = expectationWithDescription("willUpon")
		deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		signal.send(expectedValue)
		let unexpectedValue = 43
		signal.send(unexpectedValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFillableInitWithNonNilValue() {
		property("Deferred constructed with non nill value is already filled") <- {
			let expectedValue = 42
			let deferred = Deferred(expectedValue)

			let firstPeek = deferred.peek == expectedValue

			let unexpectedValue = 43
			deferred.fill(unexpectedValue)
			let secondPeek = deferred.peek == expectedValue

			return firstPeek && secondPeek
		}
	}

	func testFillableFill() {
		property("Deferred should only be filled once") <- {
			let deferred = Deferred<Int>()

			XCTAssertNil(deferred.peek)

			let expectedValue = 42
			deferred.fill(expectedValue)
			let firstPeek = deferred.peek == expectedValue

			let unexpectedValue = 43
			deferred.fill(unexpectedValue)
			let secondPeek = deferred.peek == expectedValue

			return firstPeek && secondPeek
		}
	}

	func testFillableUpon() {
		let deferred = Deferred<Int>()
		let expectedValue = 42
		let unexpectedValue = 43

		let willUpon = expectationWithDescription("willUpon")
		deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		deferred.fill(expectedValue)
		deferred.fill(unexpectedValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFillableUponReadOnly() {
		let deferred = Deferred<Int>()
		let expectedValue = 42
		let unexpectedValue = 43

		let willUpon = expectationWithDescription("willUpon")
		deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		deferred.fill(expectedValue)
		deferred.fill(unexpectedValue)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testMap() {
		let deferred = Deferred<Int>()
		let fillValue1 = 42
		let fillValue2 = 43
		let expectedValue = "42"

		let willUpon = expectationWithDescription("willUpon")

		let newDeferred: Deferred<String> = deferred.map { "\($0)" }
		newDeferred.upon { (value) in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		deferred.fill(fillValue1)
		deferred.fill(fillValue2)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFlatMap() {
		let deferred1 = Deferred<Int>()
		let deferred2 = Deferred<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willUpon1 = expectationWithDescription("willUpon1")
		let willUpon2 = expectationWithDescription("willUpon2")

		deferred1
			.flatMap { (value) -> Deferred<String> in
				XCTAssertEqual(value, expectedValue1)
				willUpon1.fulfill()
				return deferred2
			}
			.upon { value in
				XCTAssertEqual(value, expectedValue2)
				willUpon2.fulfill()
		}

		deferred1.fill(expectedValue1)
		let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime, dispatch_get_main_queue()) {
			deferred2.fill(expectedValue2)
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
