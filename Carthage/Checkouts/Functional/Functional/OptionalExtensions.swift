extension Optional {
	public func eitherWithError(_ error: @autoclosure () -> Error) -> Either<Wrapped> {
		switch self {
		case .none:
			return .left(error())
		case let .some(value):
			return .right(value)
		}
	}
}

extension Optional: Monoid {
	public static var empty: Optional {
		return nil
	}

	public func compose(_ other: Optional) -> Optional {
		return self ?? other
	}
}
