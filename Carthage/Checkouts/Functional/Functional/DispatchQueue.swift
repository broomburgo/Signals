import Foundation

public struct DispatchQueue {
	private let queue: dispatch_queue_t
	public init(_ queue: dispatch_queue_t) {
		self.queue = queue
	}

	public static var main: DispatchQueue {
		return DispatchQueue(dispatch_get_main_queue())
	}

	public func async(callback: () -> ()) {
		dispatch_async(queue, callback)
	}
}
