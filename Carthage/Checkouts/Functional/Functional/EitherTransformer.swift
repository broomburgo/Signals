extension WriterType where WrappedType: EitherType {
	public func mapT <OtherType> (transform: WrappedType.WrappedType -> OtherType) -> Writer<Either<OtherType>,LogType> {
		return map { (either) -> Either<OtherType> in
			either.map(transform)
		}
	}

	public func flatMapWT <OtherType> (transform: WrappedType.WrappedType -> Either<OtherType>) -> Writer<Either<OtherType>,LogType> {
		return flatMap { (either) -> Writer<Either<OtherType>,LogType> in
			Writer<Either<OtherType>,LogType>(either.flatMap(transform))
		}
	}

	public func flatMapT <OtherType> (transform: WrappedType.WrappedType -> Writer<Either<OtherType>,LogType>) -> Writer<Either<OtherType>,LogType> {
		return flatMap { (either) -> Writer<Either<OtherType>,LogType> in
			either.runEither(
				ifRight: { (right) -> Writer<Either<OtherType>,LogType> in
					transform(right)
				},
				ifLeft: { (left) -> Writer<Either<OtherType>,LogType> in
					Writer<Either<OtherType>,LogType>(Either<OtherType>(left))
			})
		}
	}
}
