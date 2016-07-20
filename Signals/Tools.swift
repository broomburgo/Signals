public func always <T> (callback: T -> ()) -> T -> SignalPersistence {
	return { x in
		callback(x)
		return .Continue
	}
}

public func once <T> (callback: T -> ()) -> T -> SignalPersistence {
	return { x in
		callback(x)
		return .Stop
	}
}
