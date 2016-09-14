public protocol EitherType: WrapperType {
	init(_ right: WrappedType)
	init(_ left: Error)
	func runEither <A> (ifRight: (WrappedType) -> A, ifLeft: (Error) -> A) -> A
}

extension WrapperType where Self: EitherType {
	public init(_ wrapped: WrappedType) {
		self.init(wrapped)
	}
}

//MARK: - Data
public enum Either<Wrapped>: EitherType {
	public typealias WrappedType = Wrapped

	case right(WrappedType)
	case left(Error)

	public init(_ right: WrappedType) {
		self = .right(right)
	}

	public init(_ left: Error) {
		self = .left(left)
	}

	public func runEither <A> (ifRight: (WrappedType) -> A, ifLeft: (Error) -> A) -> A {
		switch self {
		case let .right(right):
			return ifRight(right)
		case let .left(left):
			return ifLeft(left)
		}
	}

	public func get() throws -> WrappedType {
		switch self {
		case let .left(left):
			throw left
		case let .right(right):
			return right
		}
	}

	public var getOptional: WrappedType? {
		return try? get()
	}
}

//MARK: - Functor and Monad
extension EitherType {
	public func map <OtherType> (_ transform: @escaping (WrappedType) -> OtherType) -> Either<OtherType> {
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
		OtherEitherType: EitherType> (_ transform: @escaping (WrappedType) -> OtherEitherType) -> Either<OtherType>
		where
		OtherEitherType.WrappedType == OtherType
		 {
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
		OtherEitherType: EitherType>
		(_ other: OtherEitherType) -> Either<WrappedType.TargetType>
		where
		OtherEitherType.WrappedType == WrappedType.SourceType
		 {
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
	public func getOrElse(_ elseValue: @autoclosure () -> WrappedType) -> WrappedType {
		return runEither(
			ifRight: { (right) -> WrappedType in
				return right
			},
			ifLeft: { (_) -> WrappedType in
				elseValue()
		})
	}

	public func zip <
		OtherType,
		OtherEitherType: EitherType>
		(with other: OtherEitherType) -> Either<(WrappedType,OtherType)>
		where
		OtherEitherType.WrappedType == OtherType
		 {
		return flatMap { wrapped in
			other.map { other in
				(wrapped,other)
			}
		}
	}

	public static func set(_ function: () throws -> WrappedType) -> Either<WrappedType> {
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
