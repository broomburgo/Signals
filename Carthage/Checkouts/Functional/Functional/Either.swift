public protocol EitherType: WrapperType {
	init(_ right: WrappedType)
	init(_ left: ErrorType)
	func runEither <A> (@noescape ifRight ifRight: WrappedType -> A, @noescape ifLeft: ErrorType -> A) -> A
}

extension WrapperType where Self: EitherType {
	public init(_ wrapped: WrappedType) {
		self.init(wrapped)
	}
}

//MARK: - Data
public enum Either<Wrapped>: EitherType {
	public typealias WrappedType = Wrapped

	case Right(WrappedType)
	case Left(ErrorType)

	public init(_ right: WrappedType) {
		self = .Right(right)
	}

	public init(_ left: ErrorType) {
		self = .Left(left)
	}

	public func runEither <A> (@noescape ifRight ifRight: WrappedType -> A, @noescape ifLeft: ErrorType -> A) -> A {
		switch self {
		case let .Right(right):
			return ifRight(right)
		case let .Left(left):
			return ifLeft(left)
		}
	}

	public func get() throws -> WrappedType {
		switch self {
		case let .Left(left):
			throw left
		case let .Right(right):
			return right
		}
	}

	public var getOptional: WrappedType? {
		return try? get()
	}
}

//MARK: - Functor and Monad
extension EitherType {
	public func map <OtherType> (@noescape transform: WrappedType -> OtherType) -> Either<OtherType> {
		return runEither(
			ifRight: { (right) -> Either<OtherType> in
				return Either(transform(right))
			},
			ifLeft: { (left) -> Either<OtherType> in
				return Either(left)
		})
	}

	public func flatMap <
		OtherType,
		OtherEitherType: EitherType
		where
		OtherEitherType.WrappedType == OtherType
		> (@noescape transform: WrappedType -> OtherEitherType) -> Either<OtherType> {
		return runEither(
			ifRight: { (right) -> Either<OtherType> in
				return transform(right).map { $0 }
			},
			ifLeft: { (left) -> Either<OtherType> in
				return Either(left)
		})
	}
}

//MARK: - Applicative
extension EitherType where WrappedType: HomomorphismType {
	public func apply <
		OtherEitherType: EitherType
		where
		OtherEitherType.WrappedType == WrappedType.SourceType
		>
		(other: OtherEitherType) -> Either<WrappedType.TargetType> {
		return runEither(
			ifRight: { (morphism) -> Either<WrappedType.TargetType> in
				other.runEither(
					ifRight: { (value) -> Either<WrappedType.TargetType> in
						Either(morphism.direct(value))
					},
					ifLeft: { (left) -> Either<WrappedType.TargetType> in
						Either(left)
				})
			},
			ifLeft: { (left) -> Either<WrappedType.TargetType> in
				Either(left)
		})
	}
}

//MARK: - Utility
extension EitherType {
	public func getOrElse(@autoclosure elseValue: () -> WrappedType) -> WrappedType {
		return runEither(
			ifRight: { (right) -> WrappedType in
				return right
			},
			ifLeft: { (_) -> WrappedType in
				elseValue()
		})
	}

	public static func set(@noescape function: () throws -> WrappedType) -> Either<WrappedType> {
		do {
			let value = try function()
			return Either(value)
		}
		catch let error {
			return Either(error)
		}
	}
}

extension EitherType where WrappedType: Monoid {
	public var getOrEmpty: WrappedType {
		return getOrElse(WrappedType.empty)
	}
}
