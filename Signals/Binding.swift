public protocol Disconnectable {
	func disconnect()
}

public final class Binding<Wrapped>: Disconnectable {

	fileprivate var observable: AnyWeakObservable<Wrapped>?
	fileprivate var variable: AnyWeakVariable<Wrapped>?
	fileprivate var active = true

	public init<Observable: ObservableType, Variable: VariableType>(observable: Observable, variable: Variable) where Observable.ObservedType == Wrapped, Variable.VariedType == Wrapped {
		self.observable = AnyWeakObservable(observable)
		self.variable = AnyWeakVariable(variable)

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

	public func disconnect() {
		active = false
	}
}

extension ObservableType {
	public func bind<Variable>(to variable: Variable) -> Binding<ObservedType> where Variable: VariableType, Variable.VariedType == ObservedType {
		return Binding(observable: self, variable: variable)
	}
}
