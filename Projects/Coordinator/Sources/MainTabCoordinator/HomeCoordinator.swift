import HomeFeature
import PopupDetailFeatureInterface
import SearchFeatureInterface
import SwiftUI

public enum HomeCoordinatorRoute: Codable, Hashable {
    case search
    case popupDetail
}

@MainActor
public final class HomeCoordinator: Coordinator, HomeFeatureNavigating {
    public let navigationController: NavigationController

    private var searchCoordinator: SearchCoordinator?
    private var popupDetailCoordinator: PopupDetailCoordinator?

    public init() {
        self.navigationController = NavigationController()
    }

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        HomeFeatureRootView(navigator: self)
            .navigationTitle("Home")
            .navigationDestination(for: HomeCoordinatorRoute.self, destination: coordinate(_:))
    }

    public func showSearch() {
        searchCoordinator = SearchCoordinator(navigationController: navigationController)
        navigationController.push(HomeCoordinatorRoute.search)
    }

    public func showPopupDetail() {
        popupDetailCoordinator = PopupDetailCoordinator(navigationController: navigationController)
        navigationController.push(HomeCoordinatorRoute.popupDetail)
    }

    @ViewBuilder
    public func coordinate(_ route: HomeCoordinatorRoute) -> some View {
        switch route {
        case .search:
            if let searchCoordinator {
                searchCoordinator.rootView
            } else {
                unavailableView(title: "Search coordinator")
            }
        case .popupDetail:
            if let popupDetailCoordinator {
                popupDetailCoordinator.rootView
            } else {
                unavailableView(title: "Popup detail coordinator")
            }
        }
    }

    @ViewBuilder
    private func unavailableView(title: String) -> some View {
        ContentUnavailableView("\(title) unavailable", systemImage: "exclamationmark.triangle")
    }
}
