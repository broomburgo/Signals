public protocol WriterType: WrapperType {
	associatedtype LogType: Monoid
	init(_ value: WrappedType, _ info: LogType)
	var runWriter: (WrappedType,LogType) { get }
}

extension WrapperType where Self: WriterType {
	public init(_ value: WrappedType) {
		self.init(value, LogType.empty)
	}
}

//MARK: - Data
public struct Writer<Wrapped,Log: Monoid>: WriterType {
	public typealias WrappedType = Wrapped
	public typealias LogType = Log

	fileprivate let value: Wrapped
	fileprivate let info: Log
	public init(_ value: WrappedType, _ info: LogType) {
		self.value = value
		self.info = info
	}

	public var runWriter: (WrappedType, LogType) {
		return (value, info)
	}
}

//MARK: - Functor and Monad
extension WriterType {
	public func map <OtherType> (_ transform: (WrappedType) -> OtherType) -> Writer<OtherType,LogType> {
		let (value,info) = runWriter
		return Writer(transform(value),info)
	}

	public func flatMap <
		OtherType,
		OtherWriterType: WriterType>
		(_ transform: (WrappedType) -> OtherWriterType) -> Writer<OtherType,LogType>
		where
		OtherWriterType.WrappedType == OtherType,
		OtherWriterType.LogType == LogType
		 {
		let (value,info) = runWriter
		let (otherValue,otherInfo) = transform(value).runWriter
		return Writer(otherValue,info.compose(otherInfo))
	}
}

//MARK: - Applicative
extension WriterType where WrappedType: HomomorphismType {
	public func apply <
		OtherWriterType: WriterType>
		(_ other: OtherWriterType) -> Writer<WrappedType.TargetType,LogType>
		where
		OtherWriterType.WrappedType == WrappedType.SourceType,
		OtherWriterType.LogType == LogType
		 {
		let (morphism,info) = runWriter
		let (wrapped,otherInfo) = other.runWriter
		return Writer(morphism.direct(wrapped),info.compose(otherInfo))
	}
}

//MARK: - Utility
extension WriterType {
	public func tell(_ newInfo: LogType) -> Self {
		let (oldValue,oldInfo) = runWriter
		return Self(oldValue, oldInfo.compose(newInfo))
	}

	public func read(_ transform: (WrappedType) -> LogType) -> Self {
		let (oldValue,oldInfo) = runWriter
		return Self(oldValue, oldInfo.compose(transform(oldValue)))
	}

	public func censor(_ transform: (LogType) -> LogType) -> Self {
		let (oldValue,oldInfo) = runWriter
		return Self(oldValue,transform(oldInfo))
	}

	public func listen() -> Writer<(WrappedType,LogType),LogType> {
		let (oldValue,oldInfo) = runWriter
		return Writer((oldValue,oldInfo), oldInfo)
	}
}
