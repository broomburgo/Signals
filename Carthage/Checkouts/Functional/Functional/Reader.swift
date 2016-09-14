public protocol ReaderType: WrapperType {
	associatedtype EnvironmentType
	init(_ function: @escaping (EnvironmentType) -> WrappedType)
	func runReader(_ environment: EnvironmentType) -> WrappedType
}

extension WrapperType where Self: ReaderType {
	public init(_ value: WrappedType) {
		self.init { _ in value }
	}
}

//MARK: - Data
public struct Reader<Wrapped,Environment>: ReaderType {
	public typealias WrappedType = Wrapped
	public typealias EnvironmentType = Environment

	fileprivate let function: (EnvironmentType) -> WrappedType
	public init(_ function: @escaping (EnvironmentType) -> WrappedType) {
		self.function = function
	}

	public func runReader(_ environment: EnvironmentType) -> WrappedType {
		return function(environment)
	}
}

//MARK: - Functor and Monad
extension ReaderType {
	public func map <OtherType> (_ transform: @escaping (WrappedType) -> OtherType) -> Reader<OtherType,EnvironmentType> {
		return Reader { environment in
			transform(self.runReader(environment))
		}
	}

	public func flatMap <
		OtherType,
		OtherReaderType: ReaderType>
		(_ transform: @escaping (WrappedType) -> OtherReaderType) -> Reader<OtherType,EnvironmentType>
		where
		OtherReaderType.WrappedType == OtherType,
		OtherReaderType.EnvironmentType == EnvironmentType
		 {
		return Reader { environment in
			transform(self.runReader(environment)).runReader(environment)
		}
	}
}

//MARK: - Applicative
extension ReaderType where WrappedType: HomomorphismType {
	public func apply <
		OtherReaderType: ReaderType>
		(_ other: OtherReaderType) -> Reader<WrappedType.TargetType,EnvironmentType>
		where
		OtherReaderType.WrappedType == WrappedType.SourceType,
		OtherReaderType.EnvironmentType == EnvironmentType
		 {
		return Reader { environment in
			return self.runReader(environment).direct(other.runReader(environment))
		}
	}
}

//MARK: - Utility
extension ReaderType {
	public static var ask: Reader<EnvironmentType,EnvironmentType> {
		return Reader { environment in
			environment
		}
	}

	public func local(_ transform: @escaping (EnvironmentType) -> EnvironmentType) -> Self {
		return Self { environment in
			self.runReader(transform(environment))
		}
	}

	public func transfer <OtherEnvironmentType> (_ transform: @escaping (OtherEnvironmentType) -> EnvironmentType) -> Reader<WrappedType,OtherEnvironmentType> {
		return Reader { environment in
			self.runReader(transform(environment))
		}
	}
}
