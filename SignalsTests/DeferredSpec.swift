import XCTest
import Functional
import SwiftCheck
@testable import Signals

class DeferredSpec: XCTestCase {

	func testInitWithSignal() {
		let signal = Signal<Int>()
		let deferred = Deferred(nil, signal)

		let expectedValue = 42

		let willUpon = expectation(description: "willUpon")
		_ = deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		_ = signal.send(expectedValue)
		let unexpectedValue = 43
		_ = signal.send(unexpectedValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFillableInitWithNonNilValue() {
		property("Deferred constructed with non nill value is already filled") <- {
			let expectedValue = 42
			let deferred = Deferred(expectedValue)

			let firstPeek = deferred.peek == expectedValue

			let unexpectedValue = 43
			_ = deferred.fill(unexpectedValue)
			let secondPeek = deferred.peek == expectedValue

			return firstPeek && secondPeek
		}
	}

	func testFillableFill() {
		property("Deferred should only be filled once") <- {
			let deferred = Deferred<Int>()

			XCTAssertNil(deferred.peek)

			let expectedValue = 42
			_ = deferred.fill(expectedValue)
			let firstPeek = deferred.peek == expectedValue

			let unexpectedValue = 43
			_ = deferred.fill(unexpectedValue)
			let secondPeek = deferred.peek == expectedValue

			return firstPeek && secondPeek
		}
	}

	func testFillableUpon() {
		let deferred = Deferred<Int>()
		let expectedValue = 42
		let unexpectedValue = 43

		let willUpon = expectation(description: "willUpon")
		_ = deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		_ = deferred.fill(expectedValue)
		_ = deferred.fill(unexpectedValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFillableUponReadOnly() {
		let deferred = Deferred<Int>()
		let expectedValue = 42
		let unexpectedValue = 43

		let willUpon = expectation(description: "willUpon")
		_ = deferred.upon { value in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		_ = deferred.fill(expectedValue)
		_ = deferred.fill(unexpectedValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testMap() {
		let deferred = Deferred<Int>()
		let fillValue1 = 42
		let fillValue2 = 43
		let expectedValue = "42"

		let willUpon = expectation(description: "willUpon")

		let newDeferred: Deferred<String> = deferred.map { "\($0)" }
		_ = newDeferred.upon { (value) in
			XCTAssertEqual(value, expectedValue)
			willUpon.fulfill()
		}

		_ = deferred.fill(fillValue1)
		_ = deferred.fill(fillValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMap() {
		let deferred1 = Deferred<Int>()
		let deferred2 = Deferred<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willUpon1 = expectation(description: "willUpon1")
		let willUpon2 = expectation(description: "willUpon2")

		_ = deferred1
			.flatMap { (value) -> Deferred<String> in
				XCTAssertEqual(value, expectedValue1)
				willUpon1.fulfill()
				return deferred2
			}
			.upon { value in
				XCTAssertEqual(value, expectedValue2)
				willUpon2.fulfill()
		}

		_ = deferred1.fill(expectedValue1)
		let delayTime = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) {
			_ = deferred2.fill(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
