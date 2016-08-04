import Functional

public class Deferred<Wrapped>: DeferredType {
	public typealias WrappedType = Wrapped

	private var value: Wrapped?
	private let root: AnyObservable<WrappedType>
	
	init<Observable: ObservableType where Observable.ObservedType == WrappedType>(value: Wrapped?, observable: Observable) {
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
			root.onNext {
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

	public func zip<Other>(with other: Deferred<Other>) -> Deferred<(Wrapped,Other)> {
		return flatMap { (selfValue) in
			other.map { otherValue in
				(selfValue,otherValue)
			}
		}
	}
}

public final class FillableDeferred<Wrapped>: Deferred<Wrapped>, FillableDeferredType, WrapperType {
	private let signal: Signal<Wrapped>

	init(signal: Signal<Wrapped>) {
		self.signal = signal
		super.init(value: nil, observable: signal)
	}

	public convenience init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		self.init(signal: Signal<Wrapped>(workerQueue: workerQueue, callbackQueue: callbackQueue))
	}

	public func fill(value: WrappedType) -> Self {
		guard self.value == nil else { return self }
		self.value = value
		signal.send(value)
		return self
	}

	public func getReadOnly() -> Deferred<Wrapped> {
		return Deferred(value: value, observable: signal)
	}

	public init(_ value: Wrapped) {
		self.signal = Signal()
		super.init(value: value, observable: signal)
	}
}

extension Deferred {
	public func union(with other: Deferred, workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) -> Deferred {
		let fillable = FillableDeferred<Wrapped>(workerQueue: workerQueue, callbackQueue: callbackQueue)
		upon { fillable.fill($0) }
		other.upon { fillable.fill($0) }
		return fillable.getReadOnly()
	}
}
