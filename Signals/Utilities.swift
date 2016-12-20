public func always <T> (_ callback: @escaping (T) -> ()) -> (T) -> Persistence {
	return { x in
		callback(x)
		return .again
	}
}

public func once <T> (_ callback: @escaping (T) -> ()) -> (T) -> Persistence {
	return { x in
		callback(x)
		return .stop
	}
}
