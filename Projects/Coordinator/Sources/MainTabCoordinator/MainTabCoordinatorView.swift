import SwiftUI

public struct MainTabCoordinatorView: View {
    private let coordinator: MainTabCoordinator

    @MainActor
    public init(coordinator: MainTabCoordinator) {
        self.coordinator = coordinator
    }

    @MainActor
    public init(rootCoordinator: any RootCoordinating) {
        let coordinator = MainTabCoordinator()
        coordinator.rootCoordinator = rootCoordinator
        self.coordinator = coordinator
    }

    public var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabs, id: \.self) { tab in
                tabView(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
    }
}

private extension MainTabCoordinatorView {
    @ViewBuilder
    func tabView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            CoordinatedView(coordinator.homeCoordinator)
        case .map:
            CoordinatedView(coordinator.mapCoordinator)
        case .favorites:
            CoordinatedView(coordinator.favoritesCoordinator)
        case .profile:
            CoordinatedView(coordinator.profileCoordinator)
        }
    }
}
