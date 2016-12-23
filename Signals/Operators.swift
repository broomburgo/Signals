public final class MapObservable<Previous,Next>: ObservableType {
	public typealias ObservedType = Next

	fileprivate let root: AnyObservable<Previous>
	fileprivate let transform: (Previous) -> Next

	init<Observable: ObservableType>(root: Observable, transform: @escaping (Previous) -> Next) where Observable.ObservedType == Previous {
		self.root = AnyObservable(root)
		self.transform = transform
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

	fileprivate let root: AnyObservable<Previous>
	fileprivate let transform: (Previous) -> AnyObservable<Next>
	fileprivate var dependentPersistence = Persistence.again

	init<Observable: ObservableType, OtherObservable: ObservableType>(root: Observable, transform: @escaping (Previous) -> OtherObservable) where Observable.ObservedType == Previous, OtherObservable.ObservedType == Next {
		self.root = AnyObservable(root)
		self.transform = { AnyObservable(transform($0)) }
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Next) -> Persistence) -> Self {
		root.onNext { previous in
			guard self.dependentPersistence != .stop else { return .stop }
			let newObservable = self.transform(previous)
			newObservable.onNext { [weak self] value in
				guard let this = self else { return .stop }
				let newPersistence = callback(value)
				this.dependentPersistence = newPersistence
				return newPersistence
			}
			return self.dependentPersistence
		}
		return self
	}
}

public final class FilterObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyObservable<Wrapped>
	fileprivate let predicate: (Wrapped) -> Bool
	
	init<Observable: ObservableType>(root: Observable, predicate: @escaping (ObservedType) -> Bool) where Observable.ObservedType == Wrapped {
		self.root = AnyObservable(root)
		self.predicate = predicate
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

	fileprivate let emitter: Emitter<Wrapped>
	fileprivate let bindings: [Binding<Wrapped>]

	init(roots: [AnyObservable<Wrapped>]) {
		let emitter = Emitter<Wrapped>()
		let bindings =  roots.map { emitter.bind(to: $0) }

		self.emitter = emitter
		self.bindings = bindings
	}

	deinit {
		disconnectAll()
	}

	@discardableResult
	public func onNext(_ callback: @escaping (Wrapped) -> Persistence) -> Self {
		emitter.onNext { [weak self] value in
			let persistence = callback(value)
			if case .stop = persistence {
				self?.disconnectAll()
			}
			return persistence
		}
		return self
	}

	private func disconnectAll() {
		bindings.forEach { $0.disconnect() }
	}
}

public final class DebounceObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let root: AnyObservable<Wrapped>
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

		self.root = AnyObservable(root)
		self.emitter = emitter

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

public final class SingleObservable<Wrapped> {
	fileprivate let root: AnyObservable<Wrapped>

	init<Observable: ObservableType>(root: Observable) where Observable.ObservedType == Wrapped {
		self.root = AnyObservable(root)
	}

	@discardableResult
	public func upon(_ callback: @escaping (Wrapped) -> ()) -> Self {
		root.onNext { value in
			callback(value)
			return .stop
		}
		return self
	}
}

public final class CachedObservable<Wrapped>: VariableType, ObservableType {
	public typealias VariedType = Wrapped
	public typealias ObservedType = Wrapped

	fileprivate let rootObservable: AnyObservable<Wrapped>
	fileprivate let rootVariable: AnyVariable<Wrapped>
	fileprivate var cachedValue: Wrapped? = nil
	fileprivate var dependentPersistence = Persistence.again
	fileprivate var ignoreFirst: Bool = false

	init<Observable: ObservableType, Variable: VariableType>(rootObservable: Observable, rootVariable: Variable) where Observable.ObservedType == Wrapped, Variable.VariedType == Wrapped {

		self.rootObservable = AnyObservable(rootObservable)
		self.rootVariable = AnyVariable(rootVariable)
		
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.ignoreFirst == false else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			return this.dependentPersistence
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
		rootObservable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.dependentPersistence != .stop else { return .stop }
			this.cachedValue = value
			this.dependentPersistence = callback(value)
			return this.dependentPersistence
		}

		return self
	}
}
