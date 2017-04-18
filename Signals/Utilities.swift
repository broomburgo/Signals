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

public func weakly<T>(_ reference: T?, closure: @escaping (T) -> ()) -> () -> Persistence where T: AnyObject {
	return { [weak reference] in
		guard let some = reference else { return .stop }
		closure(some)
		return .again
	}
}

public func weakly<T,I>(_ reference: T?, closure: @escaping (T,I) -> ()) -> (I) -> Persistence where T: AnyObject {
	return { [weak reference] input in
		guard let some = reference else { return .stop }
		closure(some,input)
		return .again
	}
}

public func weakly<T,I1,I2>(_ reference: T?, closure: @escaping (T,I1,I2) -> ()) -> (I1,I2) -> Persistence where T: AnyObject {
	return { [weak reference] (input1, input2) in
		guard let some = reference else { return .stop }
		closure(some,input1,input2)
		return .again
	}
}

public func weakly<T,I1,I2,I3>(_ reference: T?, closure: @escaping (T,I1,I2,I3) -> ()) -> (I1,I2,I3) -> Persistence where T: AnyObject {
	return { [weak reference] (input1, input2, input3) in
		guard let some = reference else { return .stop }
		closure(some,input1,input2,input3)
		return .again
	}
}
