import Functional

public protocol DeferredType: WrapperType {
	init(optionalValue: WrappedType?)
	var peek: WrappedType? { get }
	func fill(_ value: WrappedType) -> Self
	func upon(_ callback: @escaping (WrappedType) -> ()) -> Self
}

extension WrapperType where Self: DeferredType {
	public init(_ value: WrappedType) {
		self.init(optionalValue: value)
	}
}

//MARK: - Data
public final class Deferred<Wrapped>: DeferredType {
	public typealias WrappedType = Wrapped

	fileprivate var value: WrappedType?
	fileprivate let signal: AnySignal<WrappedType>
	fileprivate let observable: AnyObservable<WrappedType>

	public init<
		SignalObservable: SignalType & ObservableType>
		(_ optionalValue: WrappedType?, _ signalObservable: SignalObservable)
		where
		SignalObservable.SentType == WrappedType,
		SignalObservable.ObservedType == WrappedType
		 {
		self.value = optionalValue
		self.signal = AnySignal(signalObservable)
		self.observable = AnyObservable(signalObservable)
	}

	public convenience init(optionalValue: WrappedType?) {
		self.init(optionalValue,Signal<WrappedType>())
	}

	public convenience init() {
		self.init(nil,Signal<WrappedType>())
	}

	public var peek: WrappedType? {
		return value
	}

	public func fill(_ value: WrappedType) -> Deferred<Wrapped> {
		guard self.value == nil else { return self }
		self.value = value
		_ = signal.send(value)
		return self
	}

	public func upon(_ callback: @escaping (WrappedType) -> ()) -> Deferred<Wrapped> {
		if let value = value {
			callback(value)
		} else {
			_ = observable.onNext {
				callback($0)
				return .stop
			}
		}
		return self
	}
}

//MARK: - Functor and Monad
extension DeferredType {
	public func map <OtherType> (_ transform: @escaping (WrappedType) -> OtherType) -> Deferred<OtherType> {
		let newDeferred = Deferred<OtherType>(optionalValue: nil)
		_ = upon { (value) in
			_ = newDeferred.fill(transform(value))
		}
		return newDeferred
	}

	public func flatMap <
		OtherType,
		OtherDeferredType: DeferredType>
		(_ transform: @escaping (WrappedType) -> OtherDeferredType) -> Deferred<OtherType>
		where
		OtherDeferredType.WrappedType == OtherType
		 {
		let newDeferred = Deferred<OtherType>(optionalValue: nil)
		_ = upon { (value) in
			_ = transform(value)
				.upon { (otherValue) in
					_ = newDeferred.fill(otherValue)
			}
		}
		return newDeferred
	}
}

//MARK: - Applicative
extension DeferredType where WrappedType: HomomorphismType {
	public func apply <
		OtherDeferredType: DeferredType>
		(_ other: OtherDeferredType) -> Deferred<WrappedType.TargetType>
		where
		OtherDeferredType.WrappedType == WrappedType.SourceType
		 {
		let newDeferred = Deferred<WrappedType.TargetType>(optionalValue: nil)
		_ = upon { (transform) in
			_ = other.upon { (value) in
				_ = newDeferred.fill(transform.direct(value))
			}
		}
		return newDeferred
	}
}

//MARK: - Utility
extension DeferredType {
	public var isFilled: Bool {
		return peek != nil
	}

	public func union <
		OtherDeferredType: DeferredType>
		(_ other: OtherDeferredType) -> Deferred<WrappedType>
		where
		OtherDeferredType.WrappedType == WrappedType
		 {
		let newDeferred = Deferred<WrappedType>(optionalValue: nil)
		_ = upon { (value) in
			_ = newDeferred.fill(value)
		}
		_ = other.upon { (value) in
			_ = newDeferred.fill(value)
		}
		return newDeferred
	}

	public func zip <
		OtherType,
		OtherDeferredType: DeferredType>
		(_ other: OtherDeferredType) -> Deferred<(WrappedType,OtherType)>
		where
		OtherDeferredType.WrappedType == OtherType
		 {
		return flatMap { selfValue in
			other.map { otherValue in
				(selfValue,otherValue)
			}
		}
	}
}

extension Deferred: ObservableType {
	public typealias ObservedType = WrappedType
	public func onNext(_ callback: @escaping (ObservedType) -> SignalPersistence) -> Self {
		_ = upon { (value) in
			_ = callback(value)
		}
		return self
	}
}
