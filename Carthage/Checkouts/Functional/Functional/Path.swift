import Foundation

public typealias PropertyList = [String:AnyObject]

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

	public func get(keys: [String]) -> Either<Target> {
		guard keys.count > 0 else { return Either.Left(errorNoKeys) }
		var plistKeys = keys
		let lastKey = plistKeys.removeLast()
		return plistKeys
			.reduce(Either.Right(root)) { current, key in
				current.flatMap { As<PropertyList>($0[key]).get.eitherWithError(errorNoPlistForKey(key)) }
			}
			.flatMap { As<Target>($0[lastKey]).get.eitherWithError(errorNoTargetForLastKey(lastKey)) }
	}

	private var errorNoKeys: NSError {
		return NSError(domain: "Path", code: 0, userInfo: [
			NSLocalizedDescriptionKey : "No keys",
			pathToErrorInfoRootPlistKey : root ])
	}

	private func errorNoPlistForKey(key: String) -> NSError {
		return NSError(domain: "Path", code: 1, userInfo: [
			NSLocalizedDescriptionKey : "No PropertyList for key \(key)",
			pathToErrorInfoRootPlistKey : root ])
	}

	private func errorNoTargetForLastKey(key: String) -> NSError {
		return NSError(domain: "Path", code: 2, userInfo: [
			NSLocalizedDescriptionKey : "No \(Target.self) for last key \(key)",
			pathToErrorInfoRootPlistKey : root ])
	}
}
