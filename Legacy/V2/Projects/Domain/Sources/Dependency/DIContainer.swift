import Foundation

public final class DIContainer {
    public static let shared = DIContainer()

    private var dependencies: [String: Any] = [:]

    private init() {}

    public func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency
    }

    public func register<T>(_ dependency: T, for type: T.Type) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }

    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let dependency = dependencies[key] as? T else {
            preconditionFailure("\(key) is not registered. Register it before resolving.")
        }
        return dependency
    }
}

@propertyWrapper
public final class Dependency<T> {
    public let wrappedValue: T

    public init() {
        self.wrappedValue = DIContainer.shared.resolve(T.self)
    }
}
