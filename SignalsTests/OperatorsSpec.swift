import XCTest
@testable import Signals

class OperatorsSpec: XCTestCase {

	func testMapSingle() {
		let emitter = Emitter<Int>()

		let sentValue1 = 42
		let expectedValue1 = "42"
		let willObserve1 = expectation(description: "willObserve1")

		emitter.map { "\($0)" }.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .again
		}

		emitter.update(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testMapChained() {
		let emitter = Emitter<Int>()

		let sentValue1 = 42
		let expectedValue1 = 84
		let expectedValue2 = "84"
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		emitter
			.map { $0*2 } .onNext { value in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .again
			}
			.map { "\($0)"}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .again
		}

		emitter.update(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapSingle() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		emitter1
			.flatMap { (value) -> Emitter<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return emitter2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .again
		}

		emitter1.update(expectedValue1)
		let delayTime = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) {
			emitter2.update(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapStop() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"
		let unexpectedValue1 = 43
		let unexpectedValue2 = "43"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")
		let willEndChain1 = expectation(description: "willEndChain1")

		emitter1
			.flatMap { (value) -> Emitter<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return emitter2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .stop
		}

		emitter1.update(expectedValue1)
		let delayTime1 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime1) {
			emitter2.update(expectedValue2)
			let delayTime2 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
			DispatchQueue.main.asyncAfter(deadline: delayTime2) {
				emitter1.update(unexpectedValue1)
				let delayTime3 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
				DispatchQueue.main.asyncAfter(deadline: delayTime3) {
					emitter2.update(unexpectedValue2)
					willEndChain1.fulfill()
				}
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFilter() {
		let emitter = Emitter<Int>()

		let unexpectedValue = 42
		let expectedValue = 43
		let willObserve = expectation(description: "willObserve")

		emitter
			.filter { $0 != unexpectedValue }
			.onNext { value in
				XCTAssertEqual(value, expectedValue)
				willObserve.fulfill()
				return .stop
		}

		emitter.update(unexpectedValue)
		emitter.update(expectedValue)
		emitter.update(expectedValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCached() {
		let emitter = Emitter<Int>()

		let expectedValue1 = 42

		let cached = emitter.cached

		emitter.update(expectedValue1)

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		let delayTime1 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime1) {
			let expectedValue2 = 43

			var observedOnce = false

			cached.onNext { value in
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

			emitter.update(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
