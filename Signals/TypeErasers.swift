//MARK: - Observable

class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped

	@discardableResult
	func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		fatalError()
	}
}

class BoxObservableWeak<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {

	weak var base: Observable?
	init(base: Observable) {
		self.base = base
	}

	@discardableResult
	override func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		base?.onNext(callback)
		return self
	}
}

public class AnyWeakObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType>(_ base: Observable) where Observable.ObservedType == ObservedType {
		self.box = BoxObservableWeak(base: base)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		box.onNext(callback)
		return self
	}
}

class BoxObservable<Observable: ObservableType>: BoxObservableBase<Observable.ObservedType> {

	let base: Observable
	init(base: Observable) {
		self.base = base
	}

	@discardableResult
	override func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		base.onNext(callback)
		return self
	}
}

public class AnyObservable<Wrapped>: ObservableType {
	public typealias ObservedType = Wrapped

	fileprivate let box: BoxObservableBase<Wrapped>

	public init<Observable: ObservableType>(_ base: Observable) where Observable.ObservedType == ObservedType {
		self.box = BoxObservable(base: base)
	}

	@discardableResult
	public func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		box.onNext(callback)
		return self
	}
}

//MARK: - Variable

class BoxVariableBase<Wrapped>: VariableType {
	typealias VariedType = Wrapped

	@discardableResult
	func update(_ value: VariedType) -> Self {
		fatalError()
	}
}

class BoxVariableWeak<Variable: VariableType>: BoxVariableBase<Variable.VariedType> {

	weak var base: Variable?
	init(base: Variable) {
		self.base = base
	}

	@discardableResult
	override func update(_ value: VariedType) -> Self {
		base?.update(value)
		return self
	}
}

public class AnyWeakVariable<Wrapped>: VariableType {
	public typealias VariedType = Wrapped

	fileprivate let box: BoxVariableBase<Wrapped>

	public init<Variable: VariableType>(_ base: Variable) where Variable.VariedType == VariedType {
		self.box = BoxVariableWeak(base: base)
	}

	@discardableResult
	public func update(_ value: VariedType) -> Self {
		box.update(value)
		return self
	}
}

class BoxVariable<Variable: VariableType>: BoxVariableBase<Variable.VariedType> {

	let base: Variable
	init(base: Variable) {
		self.base = base
	}

	@discardableResult
	override func update(_ value: VariedType) -> Self {
		base.update(value)
		return self
	}
}

public class AnyVariable<Wrapped>: VariableType {
	public typealias VariedType = Wrapped

	fileprivate let box: BoxVariableBase<Wrapped>

	public init<Variable: VariableType>(_ base: Variable) where Variable.VariedType == VariedType {
		self.box = BoxVariable(base: base)
	}

	@discardableResult
	public func update(_ value: VariedType) -> Self {
		box.update(value)
		return self
	}
}
