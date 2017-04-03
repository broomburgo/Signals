import XCTest
import Nimble
import Signals
import SwiftCheck

class ReceiverSpec: XCTestCase {

	var binding: Binding<String>? = nil

	override func tearDown() {
		super.tearDown()

		binding = nil
	}
    
	func testUpdate() {
		let receiver = Receiver<String>()
		expect(receiver.get).to(beNil())

		String.arbitrary.proliferateNonEmpty.generate.forEach {
			receiver.update($0)
			expect(receiver.get).to(equal($0))
		}
	}

	func testBind() {

		let receiver = Receiver<String>()
		expect(receiver.get).to(beNil())

		let emitter = Emitter<String>()
		binding = emitter.bind(to: receiver)

		String.arbitrary.proliferateNonEmpty.generate.forEach {
			emitter.update($0)
			expect(receiver.get).toEventually(equal($0))
		}
	}
}

class ListenerSpec: XCTestCase {

	var binding: Binding<String>? = nil

	override func tearDown() {
		super.tearDown()

		binding = nil
	}

	func testUpdate() {
		var value: String = ""
		let listener = Listener<String> {
			value = $0
		}
		expect(value).to(equal(""))

		String.arbitrary.proliferateNonEmpty.generate.forEach {
			listener.update($0)
			expect(value).to(equal($0))
		}
	}

	func testBind() {
		var value: String = ""
		let listener = Listener<String> {
			value = $0
		}
		expect(value).to(equal(""))

		let emitter = Emitter<String>()
		binding = emitter.bind(to: listener)

		String.arbitrary.proliferateNonEmpty.generate.forEach {
			emitter.update($0)
			expect(value).toEventually(equal($0))
		}
	}
}
