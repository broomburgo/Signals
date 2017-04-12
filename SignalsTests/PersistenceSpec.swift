import XCTest
@testable import Signals
import SwiftCheck

class UtilitiesSpec: XCTestCase {

	func testAlways() {
		let function: (Int) -> () = { _ in }
		let alwaysFunction = always(function)

		property("'always' always returns '.again'") <- forAll { (value: Int) in
			guard case .again = alwaysFunction(value) else { return false }
			return true
		}
	}

	func testOnce() {
		let function: (Int) -> () = { _ in }
		let onceFunction = once(function)

		property("'once' always returns '.stop'") <- forAll { (value: Int) in
			guard case .stop = onceFunction(value) else { return false }
			return true
		}
	}

	func testAsLongAsFixed() {
		let box = Box<Bool>(true)

		let function: (Int) -> () = { _ in }
		let asLongAsFunction = asLongAs { _ in box.value } (function)

		property("'asLongAs' returns '.again' if 'true', '.stop' if false") <- forAll { (value: Int, flag: Bool) in
			box.value = flag
			if flag == true {
				guard case .again = asLongAsFunction(value) else { return false }
				return true
			} else {
				guard case .stop = asLongAsFunction(value) else { return false }
				return true
			}
		}
	}

	func testAsLongAsDependent() {
		let function: (Int) -> () = { _ in }
		let asLongAsFunction = asLongAs { $0%2 == 0 } (function)

		property("'asLongAs' returns '.again' or '.stop' dependent on the value") <- forAll { (value: Int) in
			if value%2 == 0 {
				guard case .again = asLongAsFunction(value) else { return false }
				return true
			} else {
				guard case .stop = asLongAsFunction(value) else { return false }
				return true
			}
		}
	}
}
