import XCTest
@testable import Signals

class OperatorsSpec: XCTestCase {

	func testMapSingle() {
		let variable = Variable<Int>()

		let sentValue1 = 42
		let expectedValue1 = "42"
		let willObserve1 = expectation(description: "willObserve1")

		variable.map { "\($0)" }.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .again
		}

		variable.update(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testMapChained() {
		let variable = Variable<Int>()

		let sentValue1 = 42
		let expectedValue1 = 84
		let expectedValue2 = "84"
		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		variable
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

		variable.update(sentValue1)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapSingle() {
		let variable1 = Variable<Int>()
		let variable2 = Variable<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		variable1
			.flatMap { (value) -> Variable<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return variable2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .again
		}

		variable1.update(expectedValue1)
		let delayTime = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) {
			variable2.update(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFlatMapStop() {
		let variable1 = Variable<Int>()
		let variable2 = Variable<String>()

		let expectedValue1 = 42
		let expectedValue2 = "42"
		let unexpectedValue1 = 43
		let unexpectedValue2 = "43"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")
		let willEndChain1 = expectation(description: "willEndChain1")

		variable1
			.flatMap { (value) -> Variable<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				return variable2
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .stop
		}

		variable1.update(expectedValue1)
		let delayTime1 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime1) {
			variable2.update(expectedValue2)
			let delayTime2 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
			DispatchQueue.main.asyncAfter(deadline: delayTime2) {
				variable1.update(unexpectedValue1)
				let delayTime3 = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
				DispatchQueue.main.asyncAfter(deadline: delayTime3) {
					variable2.update(unexpectedValue2)
					willEndChain1.fulfill()
				}
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testFilter() {
		let variable = Variable<Int>()

		let sentValue1 = 42
		let sentValue2 = 43
		let unexpectedValue1 = 42
		let expectedValue1 = 43
		let willObserve1 = expectation(description: "willObserve1")

		variable.filter { $0 != unexpectedValue1 }.onNext { value in
			XCTAssertEqual(value, expectedValue1)
			willObserve1.fulfill()
			return .again
		}

		variable.update(sentValue1)
		variable.update(sentValue2)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCached() {
		let variable = Variable<Int>()

		let expectedValue1 = 42

		let cached = variable.cached

		variable.update(expectedValue1)

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

			variable.update(expectedValue2)
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
