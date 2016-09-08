public protocol WrapperType {
	associatedtype WrappedType
	init(_ value: WrappedType)
}

extension WrapperType where WrappedType: WrapperType {
	public init(_ value: WrappedType.WrappedType) {
		self.init(WrappedType(value))
	}
}
