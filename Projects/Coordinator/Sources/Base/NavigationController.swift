import Observation
import SwiftUI

@Observable
@MainActor
public final class NavigationController {
    public var navigationPath = NavigationPath()

    public init() {}

    public func push<Route: Codable & Hashable>(_ route: Route) {
        navigationPath.append(route)
    }

    public func dismiss() {
        guard navigationPath.isEmpty == false else { return }
        navigationPath.removeLast()
    }

    public func popToRoot() {
        navigationPath = NavigationPath()
    }
}
