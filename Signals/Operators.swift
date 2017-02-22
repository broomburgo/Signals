public final class MapObservable<Previous,Next>: Cascaded, ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyWeakObservable<Previous>
	fileprivate let transform: (Previous) -> Next

	init<Observable: ObservableType>(root: Observable, transform: @escaping (Previous) -> Next) where Observable.ObservedType == Previous {
		self.root = AnyWeakObservable(root)
		self.transform = transform
		super.init()
		root.concatenate(self)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		root.onNext { [weak self] previous in
			guard let this = self else { return .stop }
			return callback(this.transform(previous))
		}
		return self
	}
}

public final class FlatMapObservable<Previous,Next>: Cascaded, ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyWeakObservable<Previous>
	fileprivate let transform: (Previous) -> AnyObservable<Next>
	fileprivate var dependentPersistence = Persistence.again
	fileprivate var newObservable: AnyObservable<Next>? = nil

	init<Observable: ObservableType, OtherObservable: ObservableType>(root: Observable, transform: @escaping (Previous) -> OtherObservable) where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next {
		self.root = AnyWeakObservable(root)
		self.transform = { AnyObservable(transform($0)) }
		super.init()
		root.concatenate(self)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		root.onNext { [weak self] previous in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			let newObservable = this.transform(previous)
			this.newObservable = newObservable
			newObservable.onNext { value in
				let newPersistence = callback(value)
				this.dependentPersistence = newPersistence
				return newPersistence
			}
			return this.dependentPersistence
		}
		return self
	}
}

public final class FilterObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyWeakObservable<Wrapped>
	fileprivate let predicate: (Wrapped) -> Bool
	
	init<Observable: ObservableType>(root: Observable, predicate: @escaping (ObservedType) -> Bool) where Observable.ObservedType == Wrapped {
		self.root = AnyWeakObservable(root)
		self.predicate = predicate
		super.init()
		root.concatenate(self)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
			if this.predicate(value) {
				return callback(value)
			} else {
				return .again
			}
		}
		return self
	}
}

public final class UnionObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let roots: [AnyWeakObservable<Wrapped>]
	fileprivate var dependentPersistence = Persistence.again

	init(roots: AnyWeakObservable<Wrapped>...) {
		self.roots = roots
		super.init()
		roots.forEach {
			$0.concatenate(self)
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		roots.forEach {
			$0.onNext { [weak self] value in
				guard let this = self else { return .stop }
				guard this.dependentPersistence != .stop else { return .stop }
				this.dependentPersistence  = callback(value)
				return this.dependentPersistence
			}
		}
		return self
	}
}

public final class DebounceObservable<Wrapped>: Cascaded, ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyWeakObservable<Wrapped>
	fileprivate let emitter: Emitter<Wrapped>

	fileprivate var currentIdentifier: Int = 0 {
		didSet {
			if currentIdentifier == Int.max {
				currentIdentifier = 0
			}
		}
	}

	fileprivate var dependentPersistence = Persistence.again

	init<Observable: ObservableType>(root: Observable, throttleDuration: Double) where Observable.ObservedType == ObservedType {
		let emitter = Emitter<Wrapped>()

		self.root = AnyWeakObservable(root)
		self.emitter = emitter

		super.init()
		root.concatenate(self)

		root.onNext { [weak self] value in
			guard let this = self else { return .stop }
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

	fileprivate let root: AnyWeakObservable<Wrapped>
	fileprivate var cachedValue: Wrapped? = nil
	fileprivate var dependentPersistence = Persistence.again
	fileprivate let internalEmitter = Emitter<Wrapped>()

	init<Observable: ObservableType>(root: Observable) where Observable.ObservedType == Wrapped {

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

	fileprivate let emitter: Emitter<(Wrapped1,Wrapped2)>
	fileprivate let root1Observable: AnyWeakObservable<Wrapped1>
	fileprivate let root2Observable: AnyWeakObservable<Wrapped2>
	fileprivate var dependentPersistence = Persistence.again
	fileprivate var latest1: Wrapped1? = nil
	fileprivate var latest2: Wrapped2? = nil


	init<Observable1,Observable2>(root1Observable: Observable1, root2Observable: Observable2) where Observable1: ObservableType, Observable1.ObservedType == Wrapped1, Observable2: ObservableType, Observable2.ObservedType == Wrapped2 {
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

	fileprivate func emitIfPossible() {
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
