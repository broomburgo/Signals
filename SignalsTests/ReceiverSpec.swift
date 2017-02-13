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
