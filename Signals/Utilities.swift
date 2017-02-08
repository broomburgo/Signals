import Foundation

public class Cascaded: CascadedType {
	fileprivate var concatenated: [Any] = []
	public func concatenate(_ value: Any) {
		concatenated.append(value)
	}
}

extension DispatchQueue {
	public func after(_ delay: Double, callback: @escaping () -> ()) {
		let delayTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		asyncAfter(deadline: delayTime) {
			callback()
		}
	}
}
