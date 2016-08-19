import Functional

public protocol DeferredType: WrapperType {
	init(optionalValue: WrappedType?)
	var peek: WrappedType? { get }
	func fill(value: WrappedType) -> Self
	func upon(callback: WrappedType -> ()) -> Self
}

extension WrapperType where Self: DeferredType {
	public init(_ value: WrappedType) {
		self.init(optionalValue: value)
	}
}

//MARK: - Data
public final class Deferred<Wrapped>: DeferredType {
	public typealias WrappedType = Wrapped

	private var value: WrappedType?
	private let signal: AnySignal<WrappedType>
	private let observable: AnyObservable<WrappedType>

	public init<
		SignalObservable: protocol<SignalType,ObservableType>
		where
		SignalObservable.SentType == WrappedType,
		SignalObservable.ObservedType == WrappedType
		>
		(_ optionalValue: WrappedType?, _ signalObservable: SignalObservable) {
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

	public func fill(value: WrappedType) -> Deferred<Wrapped> {
		guard self.value == nil else { return self }
		self.value = value
		signal.send(value)
		return self
	}

	public func upon(callback: WrappedType -> ()) -> Deferred<Wrapped> {
		if let value = value {
			callback(value)
		} else {
			observable.onNext {
				callback($0)
				return .Stop
			}
		}
		return self
	}
}

//MARK: - Functor and Monad
extension DeferredType {
	public func map <OtherType> (transform: WrappedType -> OtherType) -> Deferred<OtherType> {
		let newDeferred = Deferred<OtherType>(optionalValue: nil)
		upon { (value) in
			newDeferred.fill(transform(value))
		}
		return newDeferred
	}

	public func flatMap <
		OtherType,
		OtherDeferredType: DeferredType
		where
		OtherDeferredType.WrappedType == OtherType
		>
		(transform: WrappedType -> OtherDeferredType) -> Deferred<OtherType> {
		let newDeferred = Deferred<OtherType>(optionalValue: nil)
		upon { (value) in
			transform(value)
				.upon { (otherValue) in
					newDeferred.fill(otherValue)
			}
		}
		return newDeferred
	}
}

//MARK: - Applicative
extension DeferredType where WrappedType: HomomorphismType {
	public func apply <
		OtherDeferredType: DeferredType
		where
		OtherDeferredType.WrappedType == WrappedType.SourceType
		>
		(other: OtherDeferredType) -> Deferred<WrappedType.TargetType> {
		let newDeferred = Deferred<WrappedType.TargetType>(optionalValue: nil)
		upon { (transform) in
			other.upon { (value) in
				newDeferred.fill(transform.direct(value))
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
		OtherDeferredType: DeferredType
		where
		OtherDeferredType.WrappedType == WrappedType
		>
		(other: OtherDeferredType) -> Deferred<WrappedType> {
		let newDeferred = Deferred<WrappedType>(optionalValue: nil)
		upon { (value) in
			newDeferred.fill(value)
		}
		other.upon { (value) in
			newDeferred.fill(value)
		}
		return newDeferred
	}

	public func zip <
		OtherType,
		OtherDeferredType: DeferredType
		where
		OtherDeferredType.WrappedType == OtherType
		>
		(other: OtherDeferredType) -> Deferred<(WrappedType,OtherType)> {
		return flatMap { selfValue in
			other.map { otherValue in
				(selfValue,otherValue)
			}
		}
	}
}

extension Deferred: ObservableType {
	public typealias ObservedType = WrappedType
	public func onNext(callback: ObservedType -> SignalPersistence) -> Self {
		upon { (value) in
			callback(value)
		}
		return self
	}
}
