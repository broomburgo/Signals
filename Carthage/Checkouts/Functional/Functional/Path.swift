import Foundation

public typealias PropertyList = [String:Any]

public struct As<A> {
	let wrapped: Any
	init(_ wrapped: Any) {
		self.wrapped = wrapped
	}

	var get: A? {
		return wrapped as? A
	}
}

public let pathToErrorInfoRootPlistKey = "pathToErrorInfoRootPlistKey"

public struct PathTo<Target> {
	let root: PropertyList
	public init(_ root: PropertyList) {
		self.root = root
	}

	public func get(_ keys: [String]) -> Either<Target> {
		guard keys.count > 0 else { return Either.left(errorNoKeys) }
		var plistKeys = keys
		let lastKey = plistKeys.removeLast()
		return plistKeys
			.reduce(Either.right(root)) { current, key in
				current.flatMap { As<PropertyList>($0[key]).get.eitherWithError(self.errorNoPlistForKey(key)) }
			}
			.flatMap { As<Target>($0[lastKey]).get.eitherWithError(self.errorNoTargetForLastKey(lastKey)) }
	}

	fileprivate var errorNoKeys: NSError {
		return NSError(domain: "Path", code: 0, userInfo: [
			NSLocalizedDescriptionKey : "No keys",
			pathToErrorInfoRootPlistKey : root ])
	}

	fileprivate func errorNoPlistForKey(_ key: String) -> NSError {
		return NSError(domain: "Path", code: 1, userInfo: [
			NSLocalizedDescriptionKey : "No PropertyList for key \(key)",
			pathToErrorInfoRootPlistKey : root ])
	}

	fileprivate func errorNoTargetForLastKey(_ key: String) -> NSError {
		return NSError(domain: "Path", code: 2, userInfo: [
			NSLocalizedDescriptionKey : "No \(Target.self) for last key \(key)",
			pathToErrorInfoRootPlistKey : root ])
	}
}
