import Foundation

public enum SignalPersistence {
	case Stop
	case Continue
}

public protocol ObservableType {
	associatedtype ObservedType
	func observe(callback: ObservedType -> SignalPersistence) -> Self
}

public protocol SignalType {
	associatedtype SentType
	func send(value: SentType) -> Self
}

private class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped
	func observe(callback: ObservedType -> SignalPersistence) -> Self {
		fatalError()
	}
}

private class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {
	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	override func observe(callback: ObservedType -> SignalPersistence) -> Self {
		base.observe(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped
	private let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType where Observable.ObservedType == ObservedType>(_ base: Observable) {
		self.box = BoxObservable(base: base)
	}

	public func observe(callback: ObservedType -> SignalPersistence) -> Self {
		box.observe(callback)
		return self
	}
}

private class FixedSignal<Wrapped>: ObservableType, SignalType {
	typealias ObservedType = Wrapped
	typealias SentType = Wrapped
	typealias Observation = ObservedType -> SignalPersistence

	var observation: (ObservedType -> SignalPersistence)? = nil

	func observe(callback: ObservedType -> SignalPersistence) -> Self {
		guard observation == nil else { return self }
		observation = callback
		return self
	}

	func send(value: ObservedType) -> Self {
		if let persistence = observation?(value) {
			switch persistence {
			case .Stop:
				observation = nil
			case .Continue:
				break
			}
		}
		return self
	}

	var isActive: Bool {
		return observation != nil
	}
}

public class AbstractSignal<Wrapped>: SignalType {
	public typealias SentType = Wrapped

	private let workerQueue: dispatch_queue_t
	private let callbackQueue: dispatch_queue_t
	private var fixed: [FixedSignal<SentType>] = []

	private init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		self.workerQueue = workerQueue
		self.callbackQueue = callbackQueue
	}

	private func observeBase(callback: SentType -> SignalPersistence) -> Self {
		fixed.append(FixedSignal<SentType>().observe(callback))
		return self
	}

	public func send(value: SentType) -> Self {
		dispatch_async(workerQueue) {
			for signal in self.fixed {
				dispatch_async(self.callbackQueue) {
					signal.send(value)
				}
			}
			dispatch_async(self.callbackQueue) {
				self.fixed = self.fixed.filter { $0.isActive }
			}
		}
		return self
	}
}

public class Signal<Wrapped>: AbstractSignal<Wrapped>, ObservableType {
	public typealias ObservedType = Wrapped

	public override init(workerQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), callbackQueue: dispatch_queue_t = dispatch_get_main_queue()) {
		super.init(workerQueue: workerQueue, callbackQueue: callbackQueue)
	}

	public func observe(callback: SentType -> SignalPersistence) -> Self {
		super.observeBase(callback)
		return self
	}
}

public class SignalMap<Previous,Next>: AbstractSignal<Previous>, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> Next
	private init<Observable: ObservableType where Observable.ObservedType == Previous>(root: Observable, transform: Previous -> Next) {
		self.root = AnyObservable(root)
		self.transform = transform
	}

	public func observe(callback: Next -> SignalPersistence) -> Self {
		root.observe { [weak self] previous in
			guard let this = self else { return .Stop }
			return callback(this.transform(previous))
		}
		return self
	}
}

public class SignalFlatMap<Previous,Next>: AbstractSignal<Previous>, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyObservable<Previous>
	private let transform: Previous -> AnyObservable<Next>
	private var dependentPersistence = SignalPersistence.Continue
	private init<Observable: ObservableType, OtherObservable: ObservableType where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next>(root: Observable, transform: Previous -> OtherObservable) {
		self.root = AnyObservable(root)
		self.transform = { AnyObservable(transform($0)) }
	}

	public func observe(callback: Next -> SignalPersistence) -> Self {
		root.observe { [weak self] previous in
			guard let this = self else { return .Stop }
			guard this.dependentPersistence != .Stop else { return .Stop }
			let newObservable = this.transform(previous)
			newObservable.observe { [weak this] value in
				guard let this = this else { return .Stop }
				let newPersistence = callback(value)
				this.dependentPersistence = newPersistence
				return newPersistence
			}
			return this.dependentPersistence
		}
		return self
	}
}

public class SignalFilter<Wrapped>: AbstractSignal<Wrapped>, ObservableType {
	public typealias ObservedType = Wrapped

	private let root: AnyObservable<Wrapped>
	private let predicate: Wrapped -> Bool
	private init<Observable: ObservableType where Observable.ObservedType == Wrapped>(root: Observable, predicate: ObservedType -> Bool) {
		self.root = AnyObservable(root)
		self.predicate = predicate
	}

	public func observe(callback: Wrapped -> SignalPersistence) -> Self {
		root.observe { [weak self] value in
			guard let this = self else { return .Stop }
			let valid = this.predicate(value)
			if valid {
				return callback(value)
			} else {
				return .Continue
			}
		}
		return self
	}
}

extension ObservableType {
	public func map<Other>(transform: ObservedType -> Other) -> AnyObservable<Other> {
		return AnyObservable(SignalMap(root: self, transform: transform))
	}

	public func flatMap<OtherObservable: ObservableType>(transform: ObservedType -> OtherObservable) -> AnyObservable<OtherObservable.ObservedType> {
		return AnyObservable(SignalFlatMap(root: self, transform: transform))
	}

	public func filter(predicate: ObservedType -> Bool) -> AnyObservable<ObservedType> {
		return AnyObservable(SignalFilter(root: self, predicate: predicate))
	}
}
