extension Bool {
	public func analyze<T>(@autoclosure ifTrue ifTrue: () -> T, @autoclosure ifFalse: () -> T) -> T {
		if self {
			return ifTrue()
		} else {
			return ifFalse()
		}
	}
}
