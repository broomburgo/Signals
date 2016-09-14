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
