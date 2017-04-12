public enum Persistence {
	case stop
	case again
}

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

public func asLongAs <T> (_ predicate: @escaping (T) -> Bool) -> (@escaping (T) -> ()) -> (T) -> Persistence {
	return { callback in
		{ x in
			guard predicate(x) else { return .stop }
			callback(x)
			return .again
		}
	}
}

