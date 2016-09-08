public protocol OptionalType: WrapperType {
	init()
	func runOptional<A>(@noescape ifSome ifSome: WrappedType -> A, @noescape ifNone: () -> A) -> A
}

//MARK: - Data
extension Optional: OptionalType {
	public typealias WrappedType = Wrapped

	public func runOptional<A>(@noescape ifSome ifSome: WrappedType -> A, @noescape ifNone: () -> A) -> A {
		if let this = self {
			return ifSome(this)
		} else {
			return ifNone()
		}
	}
}

//MARK: - Functor and Monad
extension OptionalType {
	public func map <OtherType> (@noescape transform: WrappedType -> OtherType) -> Optional<OtherType> {
		return runOptional(
			ifSome: { (wrapped) -> Optional<OtherType> in
				Optional(transform(wrapped))
			},
			ifNone: { () -> Optional<OtherType> in
				Optional()
		})
	}

	public func flatMap <
		OtherType,
		OtherOptionalType: OptionalType
		where
		OtherOptionalType.WrappedType == OtherType
		>
		(@noescape transform: WrappedType -> OtherOptionalType) -> Optional<OtherType> {
		return runOptional(
			ifSome: { (wrapped) -> Optional<OtherType> in
				transform(wrapped).map { $0 }
			},
			ifNone: { () -> Optional<OtherType> in
				Optional()
		})
	}
}

//MARK: - Applicative
extension OptionalType where WrappedType: HomomorphismType {
	public func apply <
		OtherOptionalType: OptionalType
		where
		OtherOptionalType.WrappedType == WrappedType.SourceType
		>
		(other: OtherOptionalType) -> Optional<WrappedType.TargetType> {
		return runOptional(
			ifSome: { (morphism) -> Optional<WrappedType.TargetType> in
				other.runOptional(
					ifSome: { (value) -> Optional<WrappedType.TargetType> in
						Optional(morphism.direct(value))
					},
					ifNone: { () -> Optional<WrappedType.TargetType> in
						Optional()
				})
			},
			ifNone: { () -> Optional<WrappedType.TargetType> in
				Optional()
		})
	}
}

//MARK: - Utility
extension OptionalType {
	public func getOrElse(@autoclosure elseValue: () -> WrappedType) -> WrappedType {
		return runOptional(
			ifSome: { (wrapped) -> WrappedType in
				return wrapped
			},
			ifNone: { () -> WrappedType in
				return elseValue()
		})
	}

	public var isNotNil: Bool {
		return runOptional(
			ifSome: { (_) -> Bool in
				return true
			},
			ifNone: { () -> Bool in
				return false
		})
	}

	public func ifNotNil(@noescape action: WrappedType -> ()) {
		runOptional(
			ifSome: { (wrapped) -> () in
				action(wrapped)
			},
			ifNone: { () -> () in

		})
	}

	public func filter(@noescape predicate: WrappedType -> Bool) -> Optional<WrappedType> {
		return flatMap { (wrapped) -> Optional<WrappedType> in
			if predicate(wrapped) {
				return Optional(wrapped)
			} else {
				return Optional()
			}
		}
	}

	public func zip <
		OtherType,
		OtherOptionalType: OptionalType
		where
		OtherOptionalType.WrappedType == OtherType
		>
		(@autoclosure other: () -> OtherOptionalType) -> Optional<(WrappedType,OtherType)> {
		return flatMap { selfValue in
			other().map { otherValue in
				(selfValue,otherValue)
			}
		}
	}
}

extension OptionalType where WrappedType: Monoid {
	public var getOrEmpty: WrappedType {
		return getOrElse(WrappedType.empty)
	}
}
