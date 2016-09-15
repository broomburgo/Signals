import XCTest
@testable import Signals

class OperatorsSpec: XCTestCase {

	func testMapSingle() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let expectedValue1 = "42"
		let willObserve1 = expectation(description: "willObserve1")

		signal.map { "\($0)" }.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .continue
		}

		signal.send(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testMapChained() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let expectedValue1 = 84
		let expectedValue2 = "84"
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		signal
			.map { $0*2 } .onNext { value in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .continue
			}
			.map { "\($0)"}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .continue
		}

		signal.send(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapSingle() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		signal1
			.flatMap { (value) -> Signal<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return signal2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .continue
		}

		signal1.send(expectedValue1)
		let delayTime = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) {
			signal2.send(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapStop() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"
		let unexpectedValue1 = 43
		let unexpectedValue2 = "43"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")
		let willEndChain1 = expectation(description: "willEndChain1")

		signal1
			.flatMap { (value) -> Signal<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return signal2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .stop
		}

		signal1.send(expectedValue1)
		let delayTime1 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime1) {
			signal2.send(expectedValue2)
			let delayTime2 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
			DispatchQueue.main.asyncAfter(deadline: delayTime2) {
				signal1.send(unexpectedValue1)
				let delayTime3 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
				DispatchQueue.main.asyncAfter(deadline: delayTime3) {
					signal2.send(unexpectedValue2)
					willEndChain1.fulfill()
				}
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFilter() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let sentValue2 = 43
		let unexpectedValue1 = 42
		let expectedValue1 = 43
		let willObserve1 = expectation(description: "willObserve1")

		signal.filter { $0 != unexpectedValue1 }.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .continue
		}

		signal.send(sentValue1)
		signal.send(sentValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCached() {
		let signal = Signal<Int>()

		let expectedValue1 = 42

		let cached = signal.cached

		signal.send(expectedValue1)

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
					return .continue
				} else {
					observedOnce = true
					XCTAssertEqual(value, expectedValue1)
					willObserve1.fulfill()
					return .continue
				}
			}

			signal.send(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
