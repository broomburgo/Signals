class BoxObservableBase<Wrapped>: ObservableType {
	typealias ObservedType = Wrapped

	@discardableResult
	func onNext(_ callback: @escaping (ObservedType) -> Persistence) -> Self {
		fatalError()
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

class BoxVariableBase<Wrapped>: VariableType {
	typealias WrappedType = Wrapped
	@discardableResult
	func update(_ value: WrappedType) -> Self {
		fatalError()
	}
}

class BoxVariable<Variable: VariableType>: BoxVariableBase<Variable.WrappedType> {
	let base: Variable
	init(base: Variable) {
		self.base = base
	}

	@discardableResult
	override func update(_ value: WrappedType) -> Self {
		base.update(value)
		return self
	}
}

public class AnyVariable<Wrapped>: VariableType {
	public typealias WrappedType = Wrapped
	fileprivate let box: BoxVariableBase<Wrapped>

	public init<Variable: VariableType>(_ base: Variable) where Variable.WrappedType == WrappedType {
		self.box = BoxVariable(base: base)
	}

	@discardableResult
	public func update(_ value: WrappedType) -> Self {
		box.update(value)
		return self
	}
}
