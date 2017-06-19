import Dispatch

public final class MapObservable<Previous,Next>: Cascaded, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyWeakObservable<Previous>
	private var dependentPersistence = Persistence.again
	private let internalEmitter = Emitter<Next>()

	public init<Observable: ObservableType>(root: Observable, transform: @escaping (Previous) -> Next) where Observable.ObservedType == Previous {
		self.root = AnyWeakObservable(root)
		super.init()
		root.concatenate(self)

		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.internalEmitter.update(transform(value))
			return this.dependentPersistence
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		internalEmitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}
		return self
	}
}

public final class FlatMapObservable<Previous,Next>: Cascaded, ObservableType {
	public typealias ObservedType = Next

	private let root: AnyWeakObservable<Previous>
	private let transform: (Previous) -> AnyObservable<Next>
	private var dependentPersistence = Persistence.again
	private var newObservable: AnyObservable<Next>? = nil
	private let internalEmitter = Emitter<Next>()

	public init<Observable: ObservableType, OtherObservable: ObservableType>(root: Observable, transform: @escaping (Previous) -> OtherObservable) where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next {
		self.root = AnyWeakObservable(root)
		self.transform = { AnyObservable(transform($0)) }
		super.init()
		root.concatenate(self)

		root.onNext { [weak self] previous in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			let newObservable = this.transform(previous)
			this.newObservable = newObservable
			newObservable.onNext { [weak self] value in
				guard let this = self else { return .stop }
				guard this.dependentPersistence != .stop else { return .stop }
				this.internalEmitter.update(value)
				return this.dependentPersistence
			}
			return this.dependentPersistence
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		internalEmitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}
		return self
	}
}

public final class FilterObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	private let root: AnyWeakObservable<Wrapped>
	private var dependentPersistence = Persistence.again
	private let internalEmitter = Emitter<Wrapped>()

	public init<Observable: ObservableType>(root: Observable, predicate: @escaping (ObservedType) -> Bool) where Observable.ObservedType == Wrapped {
		self.root = AnyWeakObservable(root)
		super.init()
		root.concatenate(self)

		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			if predicate(value) {
				this.internalEmitter.update(value)
			}
			return this.dependentPersistence
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		internalEmitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}
		return self
	}
}

public final class MergeObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	private let roots: [AnyWeakObservable<Wrapped>]
	private var dependentPersistence = Persistence.again
	private let internalEmitter = Emitter<Wrapped>()

	public init<Observable: ObservableType>(roots: [Observable]) where Observable.ObservedType == Wrapped {
		self.roots = roots.map(AnyWeakObservable.init)
		super.init()

		roots.forEach {
			$0.concatenate(self)
		}

		roots.forEach {
			$0.onNext { [weak self] value in
				guard let this = self else { return .stop }
				guard this.dependentPersistence != .stop else { return .stop }
				this.internalEmitter.update(value)
				return this.dependentPersistence
			}
		}
	}

	convenience init<Observable: ObservableType>(roots: Observable...) where Observable.ObservedType == Wrapped {
		self.init(roots: roots)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		internalEmitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}
		return self
	}
}

public final class DebounceObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	private let root: AnyWeakObservable<Wrapped>
	private let emitter: Emitter<Wrapped>

	private var currentIdentifier: Int = 0 {
		didSet {
			if currentIdentifier == Int.max {
				currentIdentifier = 0
			}
		}
	}

	private var dependentPersistence = Persistence.again

	public init<Observable: ObservableType>(root: Observable, throttleDuration: Double) where Observable.ObservedType == ObservedType {
		let emitter = Emitter<Wrapped>()

		self.root = AnyWeakObservable(root)
		self.emitter = emitter

		super.init()
		root.concatenate(self)

		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }

			this.currentIdentifier += 1
			let identifier = this.currentIdentifier

			DispatchQueue.main.after(throttleDuration) {
				guard identifier == this.currentIdentifier else { return }
				emitter.update(value)
			}

			return this.dependentPersistence
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {

		emitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.dependentPersistence = callback(value)
			if case .stop = this.dependentPersistence {
				this.currentIdentifier = 0
			}

			return this.dependentPersistence
		}

		return self
	}
}

public final class CachedObservable<Wrapped>: Cascaded, ObservableType {
	public typealias VariedType = Wrapped
	public typealias ObservedType = Wrapped

	private let root: AnyWeakObservable<Wrapped>
	private var cachedValue: Wrapped? = nil
	private var dependentPersistence = Persistence.again
	private let internalEmitter = Emitter<Wrapped>()

	public init<Observable: ObservableType>(root: Observable) where Observable.ObservedType == Wrapped {

		self.root = AnyWeakObservable(root)

		super.init()
		root.concatenate(self)
		
		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			this.internalEmitter.update(value)
			return this.dependentPersistence
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		if let cached = cachedValue {
			dependentPersistence = callback(cached)
		}
		internalEmitter.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}
		return self
	}
}

public final class Combine2Observable<Wrapped1,Wrapped2>: Cascaded, ObservableType {
	public typealias ObservedType = (Wrapped1,Wrapped2)

	private let emitter: Emitter<(Wrapped1,Wrapped2)>
	private let root1Observable: AnyWeakObservable<Wrapped1>
	private let root2Observable: AnyWeakObservable<Wrapped2>
	private var dependentPersistence = Persistence.again
	private var latest1: Wrapped1? = nil
	private var latest2: Wrapped2? = nil


	public init<Observable1,Observable2>(root1Observable: Observable1, root2Observable: Observable2) where Observable1: ObservableType, Observable1.ObservedType == Wrapped1, Observable2: ObservableType, Observable2.ObservedType == Wrapped2 {
		self.emitter = Emitter<(Wrapped1,Wrapped2)>()
		self.root1Observable = AnyWeakObservable(root1Observable)
		self.root2Observable = AnyWeakObservable(root2Observable)

		super.init()
		root1Observable.concatenate(self)
		root2Observable.concatenate(self)

		root1Observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.latest1 = value
			this.emitIfPossible()
			return this.dependentPersistence
		}

		root2Observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.latest2 = value
			this.emitIfPossible()
			return this.dependentPersistence
		}
	}

	private func emitIfPossible() {
		guard let latest1 = self.latest1, let latest2 = self.latest2 else { return }
		emitter.update(latest1,latest2)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped1, Wrapped2) -> Persistence) -> Self {
		emitter.onNext { [weak self] tuple in
			guard let this = self else { return .stop }
			this.dependentPersistence = callback(tuple.0,tuple.1)
			return this.dependentPersistence
		}

		return self
	}
}
