extension WriterType where WrappedType: EitherType {
	public func mapT <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> OtherType) -> Writer<Either<OtherType>,LogType> {
		return map { (either) -> Either<OtherType> in
			either.map(transform)
		}
	}

	public func flatMapWT <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> Either<OtherType>) -> Writer<Either<OtherType>,LogType> {
		return flatMap { (either) -> Writer<Either<OtherType>,LogType> in
			Writer<Either<OtherType>,LogType>(either.flatMap(transform))
		}
	}

	public func flatMapT <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> Writer<Either<OtherType>,LogType>) -> Writer<Either<OtherType>,LogType> {
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
