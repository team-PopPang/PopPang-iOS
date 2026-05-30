import Domain
import Observation

public enum MainTabRoute: Identifiable, Hashable, Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case reviewDetail([Review])

    public var id: String {
        switch self {
        case .popupDetail(let userUuid, let popup):
            "popupDetail-\(userUuid)-\(popup.popupUuid)"
        case .reviewDetail(let reviews):
            "reviewDetail-\(reviews.map(\.id.uuidString).joined(separator: "-"))"
        }
    }
}

public struct MainTabSession: Equatable, Sendable {
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
    public var route: MainTabRoute?
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
        self.route = nil
        self.selectedTab = selectedTab

        profileCoordinator.parent = self
        favoritesCoordinator.onBrowsePopups = { [weak self] in
            self?.select(.home)
        }
        homeCoordinator.onSelectPopup = { [weak self] userUuid, popup in
            self?.push(.popupDetail(userUuid: userUuid, popup: popup))
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
    }

    public func select(_ tab: MainTab) {
        selectedTab = tab
    }

    public func push(_ route: MainTabRoute) {
        guard self.route != route else { return }
        self.route = route
    }

    public func pop() {
        route = nil
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
