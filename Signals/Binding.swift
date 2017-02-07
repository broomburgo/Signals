public protocol Disposable {
	func dispose()
}

public final class DisposableBag: Disposable {
	private var bag = Array<Disposable>()

	public init() {}

	public func add(_ disposable: Disposable) {
		bag.append(disposable)
	}

	public func dispose() {
		bag.forEach { $0.dispose() }
		bag.removeAll()
	}
}

extension Disposable {
	public func add(to bag: DisposableBag) {
		bag.add(self)
	}
}

public final class Binding<Wrapped>: Disposable {

	fileprivate var observable: AnyObservable<Wrapped>?
	fileprivate var variable: AnyVariable<Wrapped>?
	fileprivate var active = true

	public init<Observable: ObservableType, Variable: VariableType>(observable: Observable, variable: Variable) where Observable.ObservedType == Wrapped, Variable.VariedType == Wrapped {
		self.observable = AnyObservable(observable)
		self.variable = AnyVariable(variable)

		observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.active else {
				this.observable = nil
				this.variable = nil
				return .stop
			}
			variable.update(value)
			return .again
		}
	}

	public func dispose() {
		active = false
	}
}

extension ObservableType {
	public func bind<Variable>(to variable: Variable) -> Binding<ObservedType> where Variable: VariableType, Variable.VariedType == ObservedType {
		return Binding(observable: self, variable: variable)
	}
}
