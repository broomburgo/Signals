public final class MapObservable<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyWeakObservable<Previous>
	fileprivate let transform: (Previous) -> Next

	init<Observable: ObservableType>(root: Observable, transform: @escaping (Previous) -> Next) where Observable.ObservedType == Previous {
		self.root = AnyWeakObservable(root)
		self.transform = transform
		root.onNext { _ in _ = self; return .again }
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		root.onNext { previous in
			return callback(self.transform(previous))
		}
		return self
	}
}

public final class FlatMapObservable<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyWeakObservable<Previous>
	fileprivate let transform: (Previous) -> AnyObservable<Next>
	fileprivate var dependentPersistence = Persistence.again

	init<Observable: ObservableType, OtherObservable: ObservableType>(root: Observable, transform: @escaping (Previous) -> OtherObservable) where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next {
		self.root = AnyWeakObservable(root)
		self.transform = { AnyObservable(transform($0)) }
		root.onNext { _ in _ = self; return self.dependentPersistence }
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		root.onNext { previous in
			guard self.dependentPersistence != .stop else { return .stop }
			let newObservable = self.transform(previous)
			newObservable.onNext { value in
				let newPersistence = callback(value)
				self.dependentPersistence = newPersistence
				return newPersistence
			}
			return self.dependentPersistence
		}
		return self
	}
}

public final class FilterObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyWeakObservable<Wrapped>
	fileprivate let predicate: (Wrapped) -> Bool
	
	init<Observable: ObservableType>(root: Observable, predicate: @escaping (ObservedType) -> Bool) where Observable.ObservedType == Wrapped {
		self.root = AnyWeakObservable(root)
		self.predicate = predicate
		root.onNext { _ in _ = self; return .again }
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		root.onNext { value in
			if self.predicate(value) {
				return callback(value)
			} else {
				return .again
			}
		}
		return self
	}
}

public final class UnionObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let roots: [AnyWeakObservable<Wrapped>]
	fileprivate var dependentPersistence = Persistence.again

	init(roots: AnyWeakObservable<Wrapped>...) {
		self.roots = roots
		roots.forEach {
			$0.onNext { _ in _ = self; return self.dependentPersistence }
		}
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		roots.forEach {
			$0.onNext { value in
				guard self.dependentPersistence != .stop else { return .stop }
				self.dependentPersistence  = callback(value)
				return self.dependentPersistence
			}
		}
		return self
	}
}

public final class DebounceObservable<Wrapped>: ObservableType {
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

		root.onNext { value in
			self.currentIdentifier += 1
			let identifier = self.currentIdentifier

			DispatchQueue.main.after(throttleDuration) {
				guard identifier == self.currentIdentifier else { return }
				emitter.update(value)
			}

			return self.dependentPersistence
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

public final class CachedObservable<Wrapped>: VariableType, ObservableType {
	public typealias VariedType = Wrapped
	public typealias ObservedType = Wrapped

	fileprivate let rootObservable: AnyWeakObservable<Wrapped>
	fileprivate let rootVariable: AnyWeakVariable<Wrapped>
	fileprivate var cachedValue: Wrapped? = nil
	fileprivate var dependentPersistence = Persistence.again
	fileprivate var ignoreFirst: Bool = false

	init<Observable: ObservableType, Variable: VariableType>(rootObservable: Observable, rootVariable: Variable) where Observable.ObservedType == Wrapped, Variable.VariedType == Wrapped {

		self.rootObservable = AnyWeakObservable(rootObservable)
		self.rootVariable = AnyWeakVariable(rootVariable)
		
		rootObservable.onNext { value in
			guard self.ignoreFirst == false else { return .stop }
			guard self.dependentPersistence != .stop else { return .stop }
			self.cachedValue = value
			return self.dependentPersistence
		}
	}

	@discardableResult
	public func update(_ value: Wrapped) -> Self {
		rootVariable.update(value)
		return self
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		ignoreFirst = true
		if let cached = cachedValue {
			dependentPersistence = callback(cached)
		}
		rootObservable.onNext { value in
			guard self.dependentPersistence != .stop else { return .stop }
			self.cachedValue = value
			self.dependentPersistence = callback(value)
			return self.dependentPersistence
		}

		return self
	}
}

public final class Combine2Observable<Wrapped1,Wrapped2>: ObservableType {
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

		root1Observable.onNext { value in
			guard self.dependentPersistence != .stop else { return .stop }
			self.latest1 = value
			self.emitIfPossible()
			return self.dependentPersistence
		}

		root2Observable.onNext { value in
			guard self.dependentPersistence != .stop else { return .stop }
			self.latest2 = value
			self.emitIfPossible()
			return self.dependentPersistence
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
