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
            HomeCoordinatorView(coordinator: coordinator.homeCoordinator)
        case .map:
            MapCoordinatorView(coordinator: coordinator.mapCoordinator)
        case .favorites:
            FavoritesCoordinatorView(coordinator: coordinator.favoritesCoordinator)
        case .profile:
            ProfileCoordinatorView(coordinator: coordinator.profileCoordinator)
        }
    }
}

private struct HomeCoordinatorView: View {
    let coordinator: HomeCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        }
    }
}

private struct MapCoordinatorView: View {
    let coordinator: MapCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        } bottomSheetView: { route in
            coordinator.buildBottomSheet(for: route)
        }
    }
}

private struct FavoritesCoordinatorView: View {
    let coordinator: FavoritesCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        }
    }
}

private struct ProfileCoordinatorView: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        }
    }
}
