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
                        tab.tabAsset(selected: coordinator.selectedTab == tab).swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text(tab.title)
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
        case .calendar:
            CalendarCoordinatorView(coordinator: coordinator.calendarCoordinator)
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
        } fullScreenView: { route in
            coordinator.buildFullScreen(for: route)
        }
    }
}

private struct CalendarCoordinatorView: View {
    let coordinator: CalendarCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
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
        }
    }
}
