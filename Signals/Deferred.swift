import Foundation
import Functional

public protocol DeferredType {
	associatedtype WrappedType

	var isFilled: Bool { get }
	func peek() -> WrappedType?
	func upon(callback: WrappedType -> ()) -> Self
}

public protocol FillableDeferredType: DeferredType {
	func fill(value: WrappedType) -> Self
}

public class Deferred<Wrapped>: DeferredType {
	public typealias WrappedType = Wrapped

	private var value: Wrapped?

	private let root: AnyObservable<WrappedType>
	private init<Observable: ObservableType where Observable.ObservedType == WrappedType>(value: Wrapped?, observable: Observable) {
		self.value = value
		self.root = AnyObservable(observable)
	}

	public var isFilled: Bool {
		return value != nil
	}

	public func peek() -> WrappedType? {
		return value
	}

	public func upon(callback: WrappedType -> ()) -> Self {
		if let value = peek() {
			callback(value)
		} else {
			root.observe {
				callback($0)
				return .Stop
			}
		}
		return self
	}

	public func map<Other>(transform: Wrapped -> Other) -> Deferred<Other> {
		return Deferred<Other>(value: value.map(transform), observable: root.map(transform))
	}

	public func flatMap<Other>(transform: Wrapped -> Deferred<Other>) -> Deferred<Other> {
		if let value = value {
			return transform(value)
		} else {
			return Deferred<Other>(value: nil, observable: root.flatMap(transform))
		}
	}

	public func filter(predicate: Wrapped -> Bool) -> Deferred<Wrapped> {
		return Deferred(value: value, observable: root.filter(predicate))
	}
}

extension Deferred: ObservableType {
	public typealias ObservedType = WrappedType

	public func observe(callback: ObservedType -> SignalPersistence) -> Self {
		return upon(callback |> ignoreOutput)
	}
}

public final class FillableDeferred<Wrapped>: Deferred<Wrapped>, FillableDeferredType {
	private let signal: Signal<Wrapped>

	public init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		self.signal = Signal<Wrapped>(workerQueue: workerQueue, callbackQueue: callbackQueue)
		super.init(value: nil, observable: signal)
	}

	public func fill(value: WrappedType) -> Self {
		guard self.value == nil else { return self }
		self.value = value
		signal.send(value)
		return self
	}

	public init(_ value: Wrapped) {
		self.signal = Signal()
		super.init(value: value, observable: signal)
	}
}
