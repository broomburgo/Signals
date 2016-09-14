import Functional

extension DeferredType where WrappedType: WriterType {
	public func mapWriterLift <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> OtherType) -> Deferred<Writer<OtherType,WrappedType.LogType>> {
		return map { (writer) -> Writer<OtherType,WrappedType.LogType> in
			writer.map(transform)
		}
	}

	public func flatMapWriterLift <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> Writer<OtherType,WrappedType.LogType>) -> Deferred<Writer<OtherType,WrappedType.LogType>> {
		return flatMap { (writer) -> Deferred<Writer<OtherType,WrappedType.LogType>> in
			Deferred<Writer<OtherType,WrappedType.LogType>>(writer.flatMap(transform))
		}
	}

	public func flatMapWriter <OtherType> (_ transform: @escaping (WrappedType.WrappedType) -> Deferred<Writer<OtherType,WrappedType.LogType>>) -> Deferred<Writer<OtherType,WrappedType.LogType>> {
		return flatMap { (writer) -> Deferred<Writer<OtherType,WrappedType.LogType>> in
			let newDeferred = Deferred<Writer<OtherType,WrappedType.LogType>>(optionalValue: nil)
			_ = transform(writer.runWriter.0).upon { (newWriter) in
				_ = newDeferred.fill(writer.flatMap { _ in newWriter})
			}
			return newDeferred
		}
	}
}
