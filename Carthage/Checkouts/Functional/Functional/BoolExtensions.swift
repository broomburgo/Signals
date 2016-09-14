extension Bool {
	public func analyze<T>(ifTrue: @autoclosure () -> T, ifFalse: @autoclosure () -> T) -> T {
		if self {
			return ifTrue()
		} else {
			return ifFalse()
		}
	}
}
