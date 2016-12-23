import Foundation
import Signals

class Box<T> {
	var value: T
	init(value: T) {
		self.value = value
	}
}

func after(_ delay: Double, callback: @escaping () -> ()) {
	DispatchQueue.main.after(delay, callback: callback)
}
