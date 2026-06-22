import Core
import Domain
import Observation

public enum MainTabRoute: Identifiable, Hashable, Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case comingPopupDetail(userUuid: String, popups: [Popup])
    case reviewDetail([Review])
    case alert(userUuid: String)
    case popupRequest(userUuid: String)
    case popupRequestManagement
    case popupRequestManagementDetail(submissionId: String)
    case profileSetting(userUuid: String, nickname: String, isAlerted: Bool)
    case notifications
    case serviceTerms

    public var id: String {
        switch self {
        case .popupDetail(let userUuid, let popup):
            "popupDetail-\(userUuid)-\(popup.popupUuid)"
        case .comingPopupDetail(let userUuid, let popups):
            "comingPopupDetail-\(userUuid)-\(popups.map(\.popupUuid).joined(separator: "-"))"
        case .reviewDetail(let reviews):
            "reviewDetail-\(reviews.map(\.id.uuidString).joined(separator: "-"))"
        case .alert(let userUuid):
            "alert-\(userUuid)"
        case .popupRequest(let userUuid):
            "popupRequest-\(userUuid)"
        case .popupRequestManagement:
            "popupRequestManagement"
        case .popupRequestManagementDetail(let submissionId):
            "popupRequestManagementDetail-\(submissionId)"
        case .profileSetting(let userUuid, let nickname, let isAlerted):
            "profileSetting-\(userUuid)-\(nickname)-\(isAlerted)"
        case .notifications:
            "notifications"
        case .serviceTerms:
            "serviceTerms"
        }
    }
}

public enum MainTabFullScreenRoute: Identifiable, Hashable, Sendable {
    case search(userUuid: String)

    public var id: String {
        switch self {
        case .search(let userUuid):
            "search-\(userUuid)"
        }
    }

    public var isPresentationAnimated: Bool {
        switch self {
        case .search:
            false
        }
    }
}

public struct MainTabSession: Equatable, Hashable, Sendable {
    public var userUuid: String
    public var nickname: String
    public var isAlerted: Bool
    public var role: String

    public init(
        userUuid: String,
        nickname: String = "닉네임",
        isAlerted: Bool = false,
        role: String = "USER"
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.role = role
    }

    public var isAdmin: Bool {
        role.uppercased() == "ADMIN"
    }
}

@Observable
@MainActor
public final class MainTabCoordinator: ProfileCoordinatorParent {
    public weak var rootCoordinator: (any RootCoordinating)?
    public let homeCoordinator: HomeCoordinator
    public let calendarCoordinator: CalendarCoordinator
    public let mapCoordinator: MapCoordinator
    public let favoritesCoordinator: FavoritesCoordinator
    public let profileCoordinator: ProfileCoordinator
    public let tabs: [MainTab]
    public var paths: [MainTabRoute]
    public var fullScreen: MainTabFullScreenRoute?
    public var selectedTab: MainTab
    public private(set) var session: MainTabSession

    public init(
        selectedTab: MainTab = .home,
        session: MainTabSession = MainTabSession(userUuid: "demo-user")
    ) {
        self.session = session
        self.homeCoordinator = HomeCoordinator(session: session)
        self.calendarCoordinator = CalendarCoordinator(session: session)
        self.mapCoordinator = MapCoordinator(session: session)
        self.favoritesCoordinator = FavoritesCoordinator(session: session)
        self.profileCoordinator = ProfileCoordinator(session: session)
        self.tabs = MainTab.allCases
        self.paths = []
        self.fullScreen = nil
        self.selectedTab = selectedTab

        profileCoordinator.parent = self
        favoritesCoordinator.onBrowsePopups = { [weak self] in
            self?.select(.home)
        }
        homeCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
        homeCoordinator.onSearch = { [weak self] userUuid in
            self?.presentFullScreen(.search(userUuid: userUuid))
        }
        homeCoordinator.onShowComingPopups = { [weak self] userUuid, popups in
            self?.push(.comingPopupDetail(userUuid: userUuid, popups: popups))
        }
        calendarCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
        mapCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
        favoritesCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
        profileCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
        }
        homeCoordinator.onShowAlert = { [weak self] userUuid in
            self?.push(.alert(userUuid: userUuid))
        }
        homeCoordinator.onReport = { [weak self] userUuid in
            self?.push(.popupRequest(userUuid: userUuid))
        }
        homeCoordinator.onManagePopupRequests = { [weak self] in
            self?.push(.popupRequestManagement)
        }
        calendarCoordinator.onShowAlert = { [weak self] userUuid in
            self?.push(.alert(userUuid: userUuid))
        }
        favoritesCoordinator.onShowAlert = { [weak self] userUuid in
            self?.push(.alert(userUuid: userUuid))
        }
        profileCoordinator.onShowAlert = { [weak self] userUuid in
            self?.push(.alert(userUuid: userUuid))
        }
        profileCoordinator.onProfileSetting = { [weak self] userUuid, nickname, isAlerted in
            self?.push(.profileSetting(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted
            ))
        }
        profileCoordinator.onNotification = { [weak self] in
            self?.push(.notifications)
        }
        profileCoordinator.onServiceTerms = { [weak self] in
            self?.push(.serviceTerms)
        }
    }

    public func select(_ tab: MainTab) {
        selectedTab = tab
    }

    public func push(_ route: MainTabRoute) {
        guard paths.last != route else { return }
        paths.append(route)
    }

    public func pop() {
        guard paths.isEmpty == false else { return }
        paths.removeLast()
    }

    public func popToRoot() {
        paths.removeAll()
    }

    public func presentFullScreen(_ route: MainTabFullScreenRoute, animated: Bool? = nil) {
        PresentationAnimation.perform(animated: animated ?? route.isPresentationAnimated) {
            fullScreen = route
        }
    }

    public func dismissFullScreen(animated: Bool? = nil) {
        PresentationAnimation.perform(animated: animated ?? fullScreen?.isPresentationAnimated ?? true) {
            fullScreen = nil
        }
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
        homeCoordinator.updateSession(session)
        calendarCoordinator.updateSession(session)
        mapCoordinator.updateSession(session)
        favoritesCoordinator.updateSession(session)
        profileCoordinator.updateSession(session)
    }

    public func logout() {
        rootCoordinator?.logout()
    }

    public func updateProfileSession(_ session: MainTabSession) {
        updateSession(session)
    }
}
