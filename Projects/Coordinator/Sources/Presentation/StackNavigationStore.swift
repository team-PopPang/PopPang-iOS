import Foundation

@MainActor
public final class StackNavigationStore<Route: Hashable>: ObservableObject {
    @Published public private(set) var path: [Route]

    public init(path: [Route] = []) {
        self.path = path
    }

    public func push(_ route: Route) {
        guard path.last != route else { return }
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    public func pop(to route: Route) {
        guard let index = path.firstIndex(of: route) else { return }
        path = Array(path.prefix(index + 1))
    }
}
