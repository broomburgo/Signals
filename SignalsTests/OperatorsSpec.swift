import XCTest
@testable import Signals
import SwiftCheck

class OperatorsSpec: XCTestCase {

	func testAny() {
		let emitter = Emitter<Int>()
		let any = AnyObservable(emitter)
		let sentValue = 42

		let willObserve = expectation(description: "willObserve1")
		any.onNext { value in
			XCTAssertEqual(value, sentValue)
			willObserve.fulfill()
			return .again
		}

		emitter.update(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testAnyWeak() {
		let emitter = Emitter<Int>()
		let anyWeak = AnyWeakObservable(emitter)
		let sentValue = 42

		let willObserve = expectation(description: "willObserve1")
		anyWeak.onNext { value in
			XCTAssertEqual(value, sentValue)
			willObserve.fulfill()
			return .again
		}

		emitter.update(sentValue)

		waitForExpectations(timeout: 1, handler: nil)
	}

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
		weak var emitter2: Emitter<String>? = nil

		let expectedValue1 = 42
		let expectedValue2 = "42"

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")

		emitter1
			.flatMap { (value) -> Emitter<String> in
				XCTAssertEqual(value, expectedValue1)
				willObserve1.fulfill()
				let newEmitter = Emitter<String>()
				emitter2 = newEmitter
				return newEmitter
			}
			.onNext { value in
				XCTAssertEqual(value, expectedValue2)
				willObserve2.fulfill()
				return .again
		}

		emitter1.update(expectedValue1)
		after(0.25) {
			emitter2!.update(expectedValue2)
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
		after(0.25) {
			emitter2.update(expectedValue2)
			after(0.25) {
				emitter1.update(unexpectedValue1)
				after(0.25) {
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

		after(0.1) {
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

	func testUnion() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let expectedValue1 = 42
		let expectedValue2 = 43
		let expectedValue3 = 44
		let unexpectedValue1 = 45
		let unexpectedValue2 = 46
		let unexpectedValue3 = 47

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")
		let willObserve3 = expectation(description: "willObserve3")

		var hasObserved1 = false
		var hasObserved2 = false
		var hasObserved3 = false

		emitter1.union(emitter2).onNext { value in
			guard hasObserved1 else {
				willObserve1.fulfill()
				XCTAssertEqual(value, expectedValue1)
				hasObserved1 = true
				return .again
			}
			guard hasObserved2 else {
				willObserve2.fulfill()
				XCTAssertEqual(value, expectedValue2)
				hasObserved2 = true
				return .again
			}
			guard hasObserved3 else {
				willObserve3.fulfill()
				XCTAssertEqual(value, expectedValue3)
				hasObserved3 = true
				return .stop
			}
			XCTAssertTrue(false)
			return .again
		}

		emitter1.update(expectedValue1)
		emitter2.update(expectedValue2)
		emitter1.update(expectedValue3)
		emitter2.update(unexpectedValue1)
		emitter1.update(unexpectedValue2)
		emitter2.update(unexpectedValue3)

		let willFinish = expectation(description: "willFinish")
		after(0.25) { 
			willFinish.fulfill()
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testDebounce() {
		let emitter = Emitter<Int>()
		let observable = emitter.debounce(0.25)

		let unexpectedValue1 = 1
		let unexpectedValue2 = 2
		let expectedValue1 = 3
		let unexpectedValue3 = 4
		let unexpectedValue4 = 5
		let expectedValue2 = 6
		let unexpectedValue5 = 7
		let unexpectedValue6 = 8
		let unexpectedValue7 = 9

		let willObserve1 = expectation(description: "willObserve1")
		let willObserve2 = expectation(description: "willObserve2")
		var hasObservedOnce = false

		observable.onNext { value in
			if hasObservedOnce == false {
				willObserve1.fulfill()
				hasObservedOnce = true
				XCTAssertEqual(value, expectedValue1)
				return .again
			} else {
				willObserve2.fulfill()
				XCTAssertEqual(value, expectedValue2)
				return .stop
			}
		}

		let willFinish = expectation(description: "willFinish")

		emitter.update(unexpectedValue1)
		after(0.1) {
			emitter.update(unexpectedValue2)
			after(0.1) {
				emitter.update(expectedValue1)
				after(0.3) {
					emitter.update(unexpectedValue3)
					after(0.1) {
						emitter.update(unexpectedValue4)
						after(0.1) {
							emitter.update(expectedValue2)
							after(0.3) {
								emitter.update(unexpectedValue5)
								after(0.1) {
									emitter.update(unexpectedValue6)
									after(0.1) {
										emitter.update(unexpectedValue7)
										after(0.3) {
											willFinish.fulfill()
										}
									}
								}
							}
						}
					}
				}
			}
		}

		waitForExpectations(timeout: 2, handler: nil)
	}

	func testCombine2() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let observable = emitter1.combine(emitter2)
		let updates: [(Int?,Int?)] = [
			(1,1),
			(nil,2),
			(nil,3),
			(2,nil),
			(3,nil),
			(4,2),
			(2,nil),
			(0,0)]
		let expected = [
			(1,1),
			(1,2),
			(1,3),
			(2,3),
			(3,3),
			(4,3),
			(4,2),
			(2,2),
			(0,2),
			(0,0)]
		let expectations = expected.map { expectation(description: "\($0)") }

		var index = 0
		let maxIndex = expected.index(before: expected.endIndex)

		observable.onNext { tuple in
			guard index <= maxIndex else { return .stop }
			let currentExpected = expected[index]
			let currentExpectation = expectations[index]
			XCTAssertEqual(currentExpected.0, tuple.0)
			XCTAssertEqual(currentExpected.1, tuple.1)
			currentExpectation.fulfill()
			index += 1
			return .again
		}

		updates.forEach { tuple in
			if let updated = tuple.0 {
				emitter1.update(updated)
			}
			if let updated = tuple.1 {
				emitter2.update(updated)
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCombine2DelayedFirstUpdate() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let observable = emitter1.combine(emitter2)
		let updates: [(Int?,Int?)] = [
			(nil,1),
			(1,nil),
			(nil,2),
			(nil,3),
			(2,nil),
			(3,nil),
			(4,2),
			(2,nil),
			(0,0)]
		let expected = [
			(1,1),
			(1,2),
			(1,3),
			(2,3),
			(3,3),
			(4,3),
			(4,2),
			(2,2),
			(0,2),
			(0,0)]
		let expectations = expected.map { expectation(description: "\($0)") }

		var index = 0
		let maxIndex = expected.index(before: expected.endIndex)

		observable.onNext { tuple in
			guard index <= maxIndex else { return .stop }
			let currentExpected = expected[index]
			let currentExpectation = expectations[index]
			XCTAssertEqual(currentExpected.0, tuple.0)
			XCTAssertEqual(currentExpected.1, tuple.1)
			currentExpectation.fulfill()
			index += 1
			return .again
		}

		updates.forEach { tuple in
			if let updated = tuple.0 {
				emitter1.update(updated)
			}
			if let updated = tuple.1 {
				emitter2.update(updated)
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCombine2EarlyStop1() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let observable = emitter1.combine(emitter2)
		let updates: [(Int?,Int?)] = [
			(1,1),
			(nil,2),
			(nil,3),
			(2,nil),
			(3,nil),
			(4,2),
			(2,nil),
			(0,0)]
		let expected = [
			(1,1),
			(1,2),
			(1,3),
			(2,3),
			(3,3),
			(4,3),
			(4,2),
			(2,2),
			(0,2),
			(0,0)]
		let actualExpected = Array(expected.prefix(3))
		let expectations = actualExpected.map { expectation(description: "\($0)") }

		var index = 0
		let maxIndex = actualExpected.index(before: actualExpected.endIndex)

		observable.onNext { tuple in
			guard index <= maxIndex else { return .stop }
			let currentExpected = expected[index]
			let currentExpectation = expectations[index]
			XCTAssertEqual(currentExpected.0, tuple.0)
			XCTAssertEqual(currentExpected.1, tuple.1)
			currentExpectation.fulfill()
			index += 1
			return .again
		}

		updates.forEach { tuple in
			if let updated = tuple.0 {
				emitter1.update(updated)
			}
			if let updated = tuple.1 {
				emitter2.update(updated)
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCombine2EarlyStop2() {
		let emitter1 = Emitter<Int>()
		let emitter2 = Emitter<Int>()

		let observable = emitter1.combine(emitter2)
		let updates: [(Int?,Int?)] = [
			(1,1),
			(nil,2),
			(nil,3),
			(2,nil),
			(3,nil),
			(4,2),
			(2,nil),
			(0,0)]
		let expected = [
			(1,1),
			(1,2),
			(1,3),
			(2,3),
			(3,3),
			(4,3),
			(4,2),
			(2,2),
			(0,2),
			(0,0)]
		let actualExpected = Array(expected.prefix(6))
		let expectations = actualExpected.map { expectation(description: "\($0)") }

		var index = 0
		let maxIndex = actualExpected.index(before: actualExpected.endIndex)

		observable.onNext { tuple in
			guard index <= maxIndex else { return .stop }
			let currentExpected = expected[index]
			let currentExpectation = expectations[index]
			XCTAssertEqual(currentExpected.0, tuple.0)
			XCTAssertEqual(currentExpected.1, tuple.1)
			currentExpectation.fulfill()
			index += 1
			return .again
		}

		updates.forEach { tuple in
			if let updated = tuple.0 {
				emitter1.update(updated)
			}
			if let updated = tuple.1 {
				emitter2.update(updated)
			}
		}

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testCombine2Login() {
		let emitter1 = Emitter<String>()
		let emitter2 = Emitter<String>()

		let rightUsername = "user"
		let wrongPassword = "wrongPass"
		let rightPassword = "correctPass"

		let wrongLoginExpectation = expectation(description: "wrongLoginExpectation")
		let rightLoginExpectation = expectation(description: "rightLoginExpectation")

		func loginIsRight(username: String, password: String) -> Bool {
			return username == rightUsername && password == rightPassword
		}

		let observable = emitter1.combine(emitter2)
		observable.onNext { (username, password) in
			if loginIsRight(username: username, password: password) {
				rightLoginExpectation.fulfill()
				return .stop
			} else {
				wrongLoginExpectation.fulfill()
				return .again
			}
		}

		emitter1.update(rightUsername)
		emitter2.update(wrongPassword)
		emitter2.update(rightPassword)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testMapSome() {
		property("'mapSome' works like default 'flatMap' for collections of optionals") <- forAll { (aa: ArrayOf<OptionalOf<Int>>, ad: String) in
			let currentExpectation = self.expectation(description: ad)

			let originalArray = aa.getArray.map { $0.getOptional }
			let filteredArray = originalArray.flatMap { $0 }
			var generatedArray: [Int] = []

			let emitter = Emitter<Int?>()
			emitter
				.mapSome { $0 }
				.onNext(always {
					generatedArray.append($0)
				})

			originalArray.forEach { emitter.update($0) }

			after(0.1) {
				XCTAssertEqual(generatedArray, filteredArray)
				currentExpectation.fulfill()
			}

			return true
		}

		waitForExpectations(timeout: 1, handler: nil)
	}
}
