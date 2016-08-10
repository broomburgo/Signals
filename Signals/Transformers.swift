import Functional

public struct WriterDeferred<Wrapped, Logger: Monoid>: WrapperType {
	public typealias WrappedType = Wrapped

	private let internalDeferred: Deferred<Writer<Wrapped,Logger>>
	init(_ internalDeferred: Deferred<Writer<Wrapped,Logger>>) {
		self.internalDeferred = internalDeferred
	}

	public init(_ writer: Writer<Wrapped,Logger>) {
		self.internalDeferred = FillableDeferred(writer)
	}

	public init(_ value: Wrapped) {
		self.internalDeferred = FillableDeferred(Writer(value))
	}

	public func get() -> Deferred<Writer<Wrapped,Logger>> {
		return internalDeferred
	}

	public func map<Other>(transform: Wrapped -> Other) -> WriterDeferred<Other,Logger> {
		return WriterDeferred<Other,Logger>(internalDeferred.map { $0.map(transform)})
	}

	public func flatMap<Other>(transform: Wrapped -> FillableDeferred<Writer<Other,Logger>>) -> WriterDeferred<Other,Logger> {
		return WriterDeferred<Other,Logger>(internalDeferred.flatMap { writer in
			let (oldValue, _) = writer.runWriter
			let newDeferred = transform(oldValue)
			return newDeferred.map { newWriter in writer.flatMap { _ in newWriter } }
			}
		)
	}
}
