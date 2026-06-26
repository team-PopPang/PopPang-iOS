import Coordinator
import SwiftUI

public struct MainTabCoordinatorView: View {
    private let coordinator: RootCoordinator

    @MainActor
    public init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.routes) {
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
            .navigationDestination(for: MainTabRoute.self) { route in
                coordinator.buildView(for: route)
            }
        }
        .fullScreenCover(item: $coordinator.fullScreen) { route in
            coordinator.buildFullScreen(for: route)
        }
    }
}

private extension MainTabCoordinatorView {
    func tabView(for tab: MainTab) -> some View {
        coordinator.buildView(for: tab)
    }
}
