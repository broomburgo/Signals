public func always <T> (_ callback: @escaping (T) -> ()) -> (T) -> SignalPersistence {
	return { x in
		callback(x)
		return .continue
	}
}

public func once <T> (_ callback: @escaping (T) -> ()) -> (T) -> SignalPersistence {
	return { x in
		callback(x)
		return .stop
	}
}
