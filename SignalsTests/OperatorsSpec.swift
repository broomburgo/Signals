import XCTest
@testable import Signals

class OperatorsSpec: XCTestCase {

	func testMapSingle() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let expectedValue1 = "42"
		let willObserve1 = expectationWithDescription("willObserve1")

		signal.map { "\($0)" }.observe { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .Continue
		}

		signal.send(sentValue1)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testMapChained() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let expectedValue1 = 84
		let expectedValue2 = "84"
		let willObserve1 = expectationWithDescription("willObserve1")
		let willObserve2 = expectationWithDescription("willObserve2")

		signal
			.map { $0*2 } .observe { value in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return .Continue
			}
			.map { "\($0)"} .observe { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .Continue
		}

		signal.send(sentValue1)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFlatMapSingle() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willObserve1 = expectationWithDescription("willObserve1")
		let willObserve2 = expectationWithDescription("willObserve2")

		signal1
			.flatMap { (value) -> Signal<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return signal2
			}
			.observe { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .Continue
		}

		signal1.send(expectedValue1)
		let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime, dispatch_get_main_queue()) {
			signal2.send(expectedValue2)
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFlatMapStop() {
		let signal1 = Signal<Int>()
		let signal2 = Signal<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"
		let unexpectedValue1 = 43
		let unexpectedValue2 = "43"

		let willObserve1 = expectationWithDescription("willObserve1")
		let willObserve2 = expectationWithDescription("willObserve2")
		let willEndChain1 = expectationWithDescription("willEndChain1")

		signal1
			.flatMap { (value) -> Signal<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return signal2
			}
			.observe { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .Stop
		}

		signal1.send(expectedValue1)
		let delayTime1 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime1, dispatch_get_main_queue()) {
			signal2.send(expectedValue2)
			let delayTime2 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
			dispatch_after(delayTime2, dispatch_get_main_queue()) {
				signal1.send(unexpectedValue1)
				let delayTime3 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
				dispatch_after(delayTime3, dispatch_get_main_queue()) {
					signal2.send(unexpectedValue2)
					willEndChain1.fulfill()
				}
			}
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testFilter() {
		let signal = Signal<Int>()

		let sentValue1 = 42
		let sentValue2 = 43
		let unexpectedValue1 = 42
		let expectedValue1 = 43
		let willObserve1 = expectationWithDescription("willObserve1")

		signal.filter { $0 != unexpectedValue1 }.observe { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .Continue
		}

		signal.send(sentValue1)
		signal.send(sentValue2)

		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testCached() {
		let signal = Signal<Int>()

		let expectedValue1 = 42

		let cached = signal.cached()

		signal.send(expectedValue1)

		let willObserve1 = expectationWithDescription("willObserve1")
		let willObserve2 = expectationWithDescription("willObserve2")

		let delayTime1 = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
		dispatch_after(delayTime1, dispatch_get_main_queue()) {
			let expectedValue2 = 43

			var observedOnce = false

			cached.observe { value in
				if observedOnce {
					XCTAssertEqual(value, expectedValue2)
					willObserve2.fulfill()
					return .Continue
				} else {
					observedOnce = true
					XCTAssertEqual(value, expectedValue1)
					willObserve1.fulfill()
					return .Continue
				}
			}

			signal.send(expectedValue2)
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
