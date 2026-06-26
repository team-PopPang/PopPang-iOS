import AlertFeature
import AlertFeatureInterface
import CalendarFeature
import CalendarFeatureInterface
import Domain
import FavoritesFeature
import FavoritesFeatureInterface
import HomeFeature
import HomeFeatureInterface
import MapFeature
import MapFeatureInterface
import PopupDetailFeature
import PopupDetailFeatureInterface
import PopupRequestFeature
import PopupRequestFeatureInterface
import PopupRequestManagementFeature
import PopupRequestManagementFeatureInterface
import ProfileFeature
import ProfileFeatureInterface
import ReviewFeature
import SearchFeature
import SearchFeatureInterface
import SwiftUI

@MainActor
private final class AlertFeatureRouterAdapter: AlertFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: AlertFeatureRoute) {
        switch route {
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
    }
}

@MainActor
private final class CalendarFeatureRouterAdapter: CalendarFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: CalendarFeatureRoute) {
        switch route {
        case .alert:
            coordinator.push(.alert(userUuid: userUuid))
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
    }
}

@MainActor
private final class FavoritesFeatureRouterAdapter: FavoritesFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: FavoritesFeatureRoute) {
        switch route {
        case .alert:
            coordinator.push(.alert(userUuid: userUuid))
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        case .selectHomeTab:
            coordinator.select(.home)
        }
    }
}

@MainActor
private final class HomeFeatureRouterAdapter: HomeFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: HomeFeatureRoute) {
        switch route {
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        case .alert:
            coordinator.push(.alert(userUuid: userUuid))
        case .search:
            coordinator.presentFullScreen(.search(userUuid: userUuid), animated: false)
        case .comingPopupDetail(let popups):
            coordinator.push(.comingPopupDetail(userUuid: userUuid, popups: popups))
        case .popupRequest:
            coordinator.push(.popupRequest(userUuid: userUuid))
        case .popupRequestManagement:
            coordinator.push(.popupRequestManagement)
        }
    }
}

@MainActor
private final class MapFeatureRouterAdapter: MapFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: MapFeatureRoute) {
        switch route {
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
    }
}

@MainActor
private final class PopupDetailFeatureRouterAdapter: PopupDetailFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: PopupDetailFeatureRoute) {
        switch route {
        case .popupDetail(let popup):
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        case .reviewDetail(let reviews):
            coordinator.push(.reviewDetail(reviews))
        case .close:
            coordinator.pop()
        }
    }
}

@MainActor
private final class PopupRequestFeatureRouterAdapter: PopupRequestFeatureRouting {
    private unowned let coordinator: RootCoordinator

    init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
    }

    func route(to route: PopupRequestFeatureRoute) {
        switch route {
        case .close:
            coordinator.pop()
        }
    }
}

@MainActor
private final class PopupRequestManagementFeatureRouterAdapter: PopupRequestManagementFeatureRouting {
    private unowned let coordinator: RootCoordinator

    init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
    }

    func route(to route: PopupRequestManagementFeatureRoute) {
        switch route {
        case .detail(let submissionId):
            coordinator.push(.popupRequestManagementDetail(submissionId: submissionId))
        case .back:
            coordinator.pop()
        }
    }
}

@MainActor
private final class ProfileFeatureRouterAdapter: ProfileFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: ProfileFeatureRoute) {
        switch route {
        case .alert:
            coordinator.push(.alert(userUuid: userUuid))
        case .profileSetting(let nickname, let isAlerted):
            coordinator.push(.profileSetting(userUuid: userUuid, nickname: nickname, isAlerted: isAlerted))
        case .notifications:
            coordinator.push(.notifications)
        case .serviceTerms:
            coordinator.push(.serviceTerms)
        case .updateNickname(let nickname):
            var updatedSession = coordinator.session
            updatedSession.nickname = nickname
            coordinator.updateSession(updatedSession)
        case .logout:
            coordinator.logout()
        }
    }
}

@MainActor
private final class SearchFeatureRouterAdapter: SearchFeatureRouting {
    private unowned let coordinator: RootCoordinator
    private let userUuid: String

    init(coordinator: RootCoordinator, userUuid: String) {
        self.coordinator = coordinator
        self.userUuid = userUuid
    }

    func route(to route: SearchFeatureRoute) {
        switch route {
        case .selectPopup(let popup):
            coordinator.dismissFullScreen(animated: false)
            coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
        case .close:
            coordinator.dismissFullScreen(animated: false)
        }
    }
}

extension RootCoordinator {
    @ViewBuilder
    func buildView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeFeatureView(
                userUuid: session.userUuid,
                nickname: session.nickname,
                isAdmin: session.isAdmin,
                router: HomeFeatureRouterAdapter(coordinator: self, userUuid: session.userUuid)
            )
            .id(session)
        case .calendar:
            CalendarFeatureView(
                userUuid: session.userUuid,
                router: CalendarFeatureRouterAdapter(coordinator: self, userUuid: session.userUuid)
            )
            .id(session)
        case .map:
            MapFeatureView(
                userUuid: session.userUuid,
                router: MapFeatureRouterAdapter(coordinator: self, userUuid: session.userUuid)
            )
            .id(session)
        case .favorites:
            FavoritesFeatureView(
                userUuid: session.userUuid,
                router: FavoritesFeatureRouterAdapter(coordinator: self, userUuid: session.userUuid)
            )
            .id(session)
        case .profile:
            ProfileFeatureView(
                userUuid: session.userUuid,
                nickname: session.nickname,
                isAlerted: session.isAlerted,
                router: ProfileFeatureRouterAdapter(coordinator: self, userUuid: session.userUuid)
            )
            .id(session)
        }
    }

    @ViewBuilder
    func buildView(for route: MainTabRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                hidesSystemTabBar: false,
                router: PopupDetailFeatureRouterAdapter(coordinator: self, userUuid: userUuid)
            )
        case .comingPopupDetail(let userUuid, let popups):
            ComingPopupDetailFeatureView(
                userUuid: userUuid,
                popups: popups,
                router: HomeFeatureRouterAdapter(coordinator: self, userUuid: userUuid)
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                router: AlertFeatureRouterAdapter(coordinator: self, userUuid: userUuid)
            )
        case .popupRequest(let userUuid):
            PopupRequestFeatureView(
                userUuid: userUuid,
                router: PopupRequestFeatureRouterAdapter(coordinator: self)
            )
        case .popupRequestManagement:
            PopupRequestManagementFeatureView(
                router: PopupRequestManagementFeatureRouterAdapter(coordinator: self)
            )
        case .popupRequestManagementDetail(let submissionId):
            PopupRequestManagementDetailFeatureView(
                submissionId: submissionId,
                router: PopupRequestManagementFeatureRouterAdapter(coordinator: self)
            )
        case .profileSetting(let userUuid, let nickname, let isAlerted):
            ProfileSettingFeatureView(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted,
                router: ProfileFeatureRouterAdapter(coordinator: self, userUuid: userUuid)
            )
        case .notifications:
            NotificationFeatureView()
        case .serviceTerms:
            ServiceTermsFeatureView()
        }
    }

    @ViewBuilder
    func buildFullScreen(for route: MainTabFullScreenRoute) -> some View {
        switch route {
        case .search(let userUuid):
            SearchFeatureView(
                userUuid: userUuid,
                nickname: session.nickname,
                router: SearchFeatureRouterAdapter(coordinator: self, userUuid: userUuid)
            )
            .accessibilityIdentifier("home_search")
        }
    }
}
