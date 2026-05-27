import Observation

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
        self.selectedTab = selectedTab

        profileCoordinator.parent = self
        favoritesCoordinator.onBrowsePopups = { [weak self] in
            self?.select(.home)
        }
    }

    public func select(_ tab: MainTab) {
        selectedTab = tab
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
