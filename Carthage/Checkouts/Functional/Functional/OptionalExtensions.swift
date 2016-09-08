extension Optional {
	public func eitherWithError(@autoclosure error: () -> ErrorType) -> Either<Wrapped> {
		switch self {
		case .None:
			return .Left(error())
		case let .Some(value):
			return .Right(value)
		}
	}
}
