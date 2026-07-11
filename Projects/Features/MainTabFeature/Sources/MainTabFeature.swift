import ComposableArchitecture
import AlertFeature
import CalendarFeature
import Core
import Domain
import FavoritesFeature
import Foundation
import HomeFeature
import MapFeature
import PopupDetailFeature
import PopupRequestFeature
import PopupRequestManagementFeature
import ProfileFeature
import ReviewFeature
import SearchFeature

public enum MainTab: Hashable, CaseIterable, Sendable {
    case home
    case calendar
    case map
    case favorites
    case profile
    
    var title: String {
        switch self {
        case .home:
            "홈"
        case .calendar:
            "캘린더"
        case .map:
            "팝팡지도"
        case .favorites:
            "팝팡"
        case .profile:
            "마이"
        }
    }
    
    private var rawImageName: String {
        switch self {
        case .home:
            "home"
        case .calendar:
            "calendar"
        case .map:
            "map"
        case .favorites:
            "favorite"
        case .profile:
            "profile"
        }
    }
    
    func tabImageName(selected: Bool) -> String {
        selected ? "\(rawImageName)_fill" : rawImageName
    }
}

@Reducer
public struct MainTabFeature {
    @Reducer
    public enum Destination {
        case search(SearchDestinationFeature)
        case popupRequest(PopupRequestFeature)
    }

    @ObservableState
    public struct CoreState: Equatable {
        var selectedTab: MainTab = .home
        var calendar: CalendarFeature.State
        var favorites: FavoritesFeature.State
        var home: HomeFeature.State
        var map: MapFeature.State
        var profile: ProfileFeature.State
        @Presents var destination: Destination.State?
        var path = StackState<Path.State>()

        public init(session: Shared<UserSession>) {
            self.calendar = .init(session: session)
            self.favorites = .init(session: session)
            self.home = .init(session: session)
            self.map = .init(session: session)
            self.profile = .init(session: session)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab
            && lhs.calendar == rhs.calendar
            && lhs.favorites == rhs.favorites
            && lhs.home == rhs.home
            && lhs.map == rhs.map
            && lhs.profile == rhs.profile
            && destinationsEqual(lhs.destination, rhs.destination)
        }

        private static func destinationsEqual(
            _ lhs: Destination.State?,
            _ rhs: Destination.State?
        ) -> Bool {
            switch (lhs, rhs) {
            case (.search(let lhsState), .search(let rhsState)):
                lhsState == rhsState
            case (.popupRequest(let lhsState), .popupRequest(let rhsState)):
                lhsState == rhsState
            case (nil, nil):
                true
            default:
                false
            }
        }
    }
    
    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
        public var core: CoreState
        
        public init(
            session: Shared<UserSession>,
            core: CoreState? = nil
        ) {
            self._session = session
            self.core = core ?? .init(session: session)
        }

        var currentUser: User {
            guard let user = session.user else {
                preconditionFailure("MainTabFeature requires a logged in user.")
            }
            return user
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.session == rhs.session
            && lhs.core == rhs.core
        }
    }
    
    public enum Action {
        case selectedTabChanged(MainTab)
        case calendar(CalendarFeature.Action)
        case favorites(FavoritesFeature.Action)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case profile(ProfileFeature.Action)
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<Path>)
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case logout
        }
    }
    
    @Reducer
    public enum Path {
        case popupRequestManagement(PopupRequestManagementFlowFeature)
        case popupRequestManagementDetail(PopupRequestManagementDetailFeature)
        case homeComingPopupDetail(HomeComingPopupDetailDestinationFeature)
        case popupDetail(PopupDetailDestinationFeature)
        case reviewDetail(ReviewFeature)
        case alert(AlertFeature)
        case profileSetting(ProfileSettingFeature)
        case notifications(NotificationDestinationFeature)
        case serviceTerms(ServiceTermsDestinationFeature)
    }
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.core.calendar, action: \.calendar) {
            CalendarFeature()
        }
        Scope(state: \.core.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.core.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.core.favorites, action: \.favorites) {
            FavoritesFeature()
        }
        Scope(state: \.core.profile, action: \.profile) {
            ProfileFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .selectedTabChanged(let tab):
                state.core.selectedTab = tab
                return .none
                
            case .home(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none
                
            case .calendar(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none
                
            case .favorites(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none
                
            case .map(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none
                
            case .home(.delegate(.comingPopupsRequested(let popups))):
                state.core.path.append(
                    .homeComingPopupDetail(
                        .init(
                            userUuid: state.currentUser.userUuid,
                            popups: popups
                        )
                    )
                )
                return .none
                
            case .home(.delegate(.popupRequestManagementRequested)):
                state.core.path.append(
                    .popupRequestManagement(
                        .init(adminUuid: state.currentUser.userUuid)
                    )
                )
                return .none
                
            case .home(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(session: state.$session)))
                return .none
                
            case .calendar(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(session: state.$session)))
                return .none
                
            case .home(.delegate(.searchRequested)):
                state.core.destination = .search(
                    .init(
                        userUuid: state.currentUser.userUuid,
                        nickname: state.currentUser.displayNickname
                    )
                )
                return .none

            case .home(.delegate(.popupRequestRequested)):
                state.core.destination = .popupRequest(
                    .init(userUuid: state.currentUser.userUuid)
                )
                return .none

            case .favorites(.delegate(.browsePopupsRequested)):
                state.core.selectedTab = .home
                return .none
                
            case .favorites(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(session: state.$session)))
                return .none
                
            case .profile(.delegate(.profileSettingRequested)):
                state.core.path.append(
                    .profileSetting(.init(session: state.$session))
                )
                return .none
                
            case .profile(.delegate(.notificationsRequested)):
                state.core.path.append(.notifications(.init()))
                return .none
                
            case .profile(.delegate(.serviceTermsRequested)):
                state.core.path.append(.serviceTerms(.init()))
                return .none
                
            case .profile(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(session: state.$session)))
                return .none

            case .destination(.presented(.search(.delegate(.dismiss)))):
                state.core.destination = nil
                return .none

            case .destination(.presented(.popupRequest(.delegate(.dismiss)))):
                state.core.destination = nil
                return .none
                
            case .home,
                    .calendar,
                    .map,
                    .favorites,
                    .profile:
                return .none
                
            case .path(.element(let id, let action)):
                return reducePathAction(id: id, action: action, state: &state)
                
            case .destination:
                return .none

            case .path:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.core.path, action: \.path)
        .ifLet(\.core.$destination, action: \.destination)
    }
}

private extension MainTabFeature {
    func appendPopupDetail(_ popup: Popup, state: inout State) {
        state.core.path.append(
            .popupDetail(
                .init(
                    userUuid: state.currentUser.userUuid,
                    popup: popup,
                    isAdmin: state.currentUser.isAdminRole
                )
            )
        )
    }
    
    func reducePathAction(
        id: StackElementID,
        action: Path.Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .popupRequestManagement(.delegate(.dismiss)):
            state.core.path.pop(from: id)
            return .none
            
        case .popupRequestManagement(.delegate(.showDetail(let submissionId))):
            state.core.path.append(
                .popupRequestManagementDetail(
                    .init(
                        adminUuid: state.currentUser.userUuid,
                        submissionId: submissionId
                    )
                )
            )
            return .none
            
        case .popupRequestManagementDetail(.delegate(.pop)):
            state.core.path.pop(from: id)
            return .none
            
        case .homeComingPopupDetail(.delegate(.selectPopup(let popup))):
            appendPopupDetail(popup, state: &state)
            return .none
            
        case .popupDetail(.delegate(.pushPopupDetail(_, let popup))),
                .alert(.delegate(.popupSelected(let popup))):
            appendPopupDetail(popup, state: &state)
            return .none
            
        case .popupDetail(.delegate(.showReviews(let reviews))):
            state.core.path.append(.reviewDetail(.init(reviews: reviews)))
            return .none

        case let .popupDetail(.delegate(.favoriteChanged(popupUuid, isFavorited, favoriteCount))):
            return .send(.home(.favoriteUpdated(
                popupUuid: popupUuid,
                isFavorited: isFavorited,
                favoriteCount: favoriteCount
            )))
            
        case .popupDetail(.delegate(.close)):
            state.core.path.pop(from: id)
            return .none
            
        case .profileSetting(.delegate(.logoutRequested)):
            return .send(.delegate(.logout))

        case .profileSetting(.delegate(.dismiss)):
            state.core.path.pop(from: id)
            return .none
            
        default:
            return .none
        }
    }
}

extension User {
    var displayNickname: String {
        nickname ?? "닉네임"
    }
    
    var isAdminRole: Bool {
        role.uppercased() == "ADMIN"
    }
}

@Reducer
public struct PopupDetailDestinationFeature {
    @ObservableState
    public struct State: Equatable {
        var content: PopupDetailFeature.State
        let isAdmin: Bool
        let hidesSystemTabBar: Bool

        public init(
            userUuid: String,
            popup: Popup,
            isAdmin: Bool,
            hidesSystemTabBar: Bool = false
        ) {
            self.content = .init(
                userUuid: userUuid,
                popup: popup
            )
            self.isAdmin = isAdmin
            self.hidesSystemTabBar = hidesSystemTabBar
        }
    }
    
    public enum Action: Equatable {
        case content(PopupDetailFeature.Action)
        case relatedPopupSelected(String, Popup)
        case deactivateCompleted
        case reviewsTapped([Review])
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case pushPopupDetail(String, Popup)
            case showReviews([Review])
            case favoriteChanged(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
            case close
        }
    }
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.content, action: \.content) {
            PopupDetailFeature()
        }

        Reduce { _, action in
            switch action {
            case let .content(.delegate(.favoriteChanged(popupUuid, isFavorited, favoriteCount))):
                return .send(.delegate(.favoriteChanged(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )))
            case .content:
                return .none
            case .relatedPopupSelected(let userUuid, let popup):
                return .send(.delegate(.pushPopupDetail(userUuid, popup)))
            case .deactivateCompleted:
                return .send(.delegate(.close))
            case .reviewsTapped(let reviews):
                return .send(.delegate(.showReviews(reviews)))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
public struct SearchDestinationFeature {
    @Reducer
    public enum Path {
        case popupDetail(PopupDetailDestinationFeature)
        case reviewDetail(ReviewFeature)
    }

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: UUID { search.id }
        var search: SearchFeature.State
        var path = StackState<Path.State>()

        public init(
            userUuid: String,
            nickname: String
        ) {
            self.search = .init(
                userUuid: userUuid,
                nickname: nickname
            )
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.search == rhs.search
        }
    }

    public enum Action {
        case search(SearchFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.search, action: \.search) {
            SearchFeature()
        }

        Reduce { state, action in
            switch action {
            case .search(.delegate(.dismiss)):
                return .send(.delegate(.dismiss))

            case .search(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none

            case .path(.element(let id, let action)):
                return reducePathAction(id: id, action: action, state: &state)

            case .search,
                    .path,
                    .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

private extension SearchDestinationFeature {
    func appendPopupDetail(_ popup: Popup, state: inout State) {
        state.path.append(
            .popupDetail(
                .init(
                    userUuid: state.search.userUuid,
                    popup: popup,
                    isAdmin: false,
                    hidesSystemTabBar: true
                )
            )
        )
    }

    func reducePathAction(
        id: StackElementID,
        action: Path.Action,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .popupDetail(.delegate(.pushPopupDetail(_, let popup))):
            appendPopupDetail(popup, state: &state)
            return .none

        case .popupDetail(.delegate(.showReviews(let reviews))):
            state.path.append(.reviewDetail(.init(reviews: reviews)))
            return .none

        case .popupDetail(.delegate(.close)):
            state.path.pop(from: id)
            return .none

        default:
            return .none
        }
    }
}

@Reducer
public struct NotificationDestinationFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {}
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}

@Reducer
public struct ServiceTermsDestinationFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {}
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
