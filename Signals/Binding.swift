//public protocol BindableType {
//	associatedtype BoundType
//	func bind<Observable: ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType
//}
//
//extension VariableType where Self: BindableType, VariedType == Self.BoundType {
//	public func bind<Observable : ObservableType>(to observable: Observable) where Observable.ObservedType == BoundType {
//		observable.onNext { [weak self] value in
//			guard let this = self else { return .stop }
//			this.update(value)
//			return .again
//		}
//	}
//}
//
//extension Emitter: BindableType {
//	public typealias BoundType = VariedType
//}
//
//extension CachedObservable: BindableType {
//	public typealias BoundType = VariedType
//}

public final class Binding<Wrapped> {

	fileprivate var observable: AnyObservable<Wrapped>?
	fileprivate var variable: AnyVariable<Wrapped>?
	fileprivate var active = true

	public init<Observable: ObservableType, Variable: VariableType>(observable: Observable, variable: Variable) where Observable.ObservedType == Wrapped, Variable.VariedType == Wrapped {
		self.observable = AnyObservable(observable)
		self.variable = AnyVariable(variable)

		observable.onNext { [weak self] value in
			guard let this = self else { return .stop }
			guard this.active else {
				this.clean()
				return .stop
			}
			variable.update(value)
			return .again
		}
	}

	public func disconnect() {
		active = false
	}

	fileprivate func clean() {
		active = false
		observable = nil
		variable = nil
	}
}
