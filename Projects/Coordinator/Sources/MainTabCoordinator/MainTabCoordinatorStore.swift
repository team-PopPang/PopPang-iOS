import Observation

@Observable
@MainActor
public final class MainTabCoordinator: ProfileCoordinatorParent {
    public weak var rootCoordinator: (any RootCoordinating)?
    public let homeCoordinator: HomeCoordinator
    public let mapCoordinator: MapCoordinator
    public let favoritesCoordinator: FavoritesCoordinator
    public let profileCoordinator: ProfileCoordinator
    public let tabs: [MainTab]
    public var selectedTab: MainTab

    public init(selectedTab: MainTab = .home) {
        self.homeCoordinator = HomeCoordinator()
        self.mapCoordinator = MapCoordinator()
        self.favoritesCoordinator = FavoritesCoordinator()
        self.profileCoordinator = ProfileCoordinator()
        self.tabs = MainTab.allCases
        self.selectedTab = selectedTab

        profileCoordinator.parent = self
    }

    public func select(_ tab: MainTab) {
        selectedTab = tab
    }

    public func showAuthFlow() {
        rootCoordinator?.showAuthFlow()
    }
}
