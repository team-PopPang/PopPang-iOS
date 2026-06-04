import AlertFeature
import HomeFeature
import PopupDetailFeature
import PopupReportFeature
import ProfileFeature
import ReviewFeature
import SearchFeature
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

        NavigationStack(path: $coordinator.paths) {
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
                destination(for: route)
            }
        }
        .fullScreenCover(item: $coordinator.fullScreen) { route in
            fullScreenDestination(for: route)
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

    @ViewBuilder
    func destination(for route: MainTabRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: coordinator.session.isAdmin,
                hidesSystemTabBar: false,
                onSelectRelatedPopup: { userUuid, popup in
                    coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
                },
                onShowReviews: { reviews in
                    coordinator.push(.reviewDetail(reviews))
                }
            )
        case let .comingPopupDetail(userUuid, popups):
            ComingPopupDetailFeatureView(
                userUuid: userUuid,
                popups: popups,
                onSelectPopup: { userUuid, popup in
                    coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                onSelectPopup: { userUuid, popup in
                    coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .popupReport(let userUuid):
            PopupReportFeatureView(
                userUuid: userUuid,
                onDismiss: {
                    coordinator.pop()
                }
            )
        case let .profileSetting(userUuid, nickname, isAlerted):
            ProfileSettingFeatureView(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted,
                onLogout: {
                    coordinator.logout()
                },
                onNicknameUpdated: { nickname in
                    var updatedSession = coordinator.session
                    updatedSession.nickname = nickname
                    coordinator.updateProfileSession(updatedSession)
                }
            )
        case .notifications:
            NotificationFeatureView()
        case .serviceTerms:
            ServiceTermsFeatureView()
        }
    }

    @ViewBuilder
    func fullScreenDestination(for route: MainTabFullScreenRoute) -> some View {
        switch route {
        case .search(let userUuid):
            SearchFeatureView(
                userUuid: userUuid,
                nickname: coordinator.session.nickname,
                onDismiss: {
                    coordinator.dismissFullScreen()
                },
                onSelectPopup: { popup in
                    coordinator.dismissFullScreen()
                    coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
            .accessibilityIdentifier("home_search")
        }
    }
}

private struct HomeCoordinatorView: View {
    let coordinator: HomeCoordinator

    var body: some View {
        coordinator.makeRootView()
            .environment(coordinator)
    }
}

private struct CalendarCoordinatorView: View {
    let coordinator: CalendarCoordinator

    var body: some View {
        coordinator.makeRootView()
            .environment(coordinator)
    }
}

private struct MapCoordinatorView: View {
    let coordinator: MapCoordinator

    var body: some View {
        coordinator.makeRootView()
            .environment(coordinator)
    }
}

private struct FavoritesCoordinatorView: View {
    let coordinator: FavoritesCoordinator

    var body: some View {
        coordinator.makeRootView()
            .environment(coordinator)
    }
}

private struct ProfileCoordinatorView: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        coordinator.makeRootView()
            .environment(coordinator)
    }
}
