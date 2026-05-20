import Foundation

@MainActor
public final class FullScreenPresentationStore<Route: Identifiable>: ObservableObject {
    @Published public private(set) var route: Route?

    public init(route: Route? = nil) {
        self.route = route
    }

    public func present(_ route: Route) {
        self.route = route
    }

    public func dismiss() {
        route = nil
    }
}
