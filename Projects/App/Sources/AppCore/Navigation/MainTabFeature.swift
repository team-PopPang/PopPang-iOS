import ComposableArchitecture
import Core
import Domain
import struct HomeFeature.HomeComingPopupDetailDestinationFeature
import struct HomeFeature.HomeFeature
import PopupDetailFeature
import PopupRequestManagementFeature
import ProfileFeature

enum MainTab: Hashable, CaseIterable, Sendable {
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
struct MainTabFeature {
    @ObservableState
    struct CoreState: Equatable {
        var selectedTab: MainTab = .home
        var home: HomeFeature.State
        var profile: ProfileFeature.State
        var path = StackState<Path.State>()

        init(session: Shared<UserSession>) {
            self.home = .init(session: session)
            self.profile = .init(session: session)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab
            && lhs.home == rhs.home
            && lhs.profile == rhs.profile
        }
    }
    
    @ObservableState
    struct State: Equatable {
        @Shared var session: UserSession
        var core: CoreState
        
        init(
            session: Shared<UserSession>,
            core: CoreState? = nil
        ) {
            self._session = session
            self.core = core ?? .init(session: session)
        }
        
        // Legacy tabs still own Compound/internal state, so MainTab only bridges session-derived primitives for now.
        var calendar: CalendarLegacyBridgeFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }
        
        var map: MapLegacyBridgeFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }
        
        var favorites: FavoritesLegacyBridgeFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }
        
        var currentUser: User {
            guard let user = session.user else {
                preconditionFailure("MainTabFeature requires a logged in user.")
            }
            return user
        }
        
        var sessionContext: SessionContext {
            guard let context = session.context else {
                preconditionFailure("MainTabFeature requires session context.")
            }
            return context
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.session == rhs.session
            && lhs.core == rhs.core
        }
    }
    
    enum Action {
        case selectedTabChanged(MainTab)
        case home(HomeFeature.Action)
        case calendar(CalendarLegacyBridgeFeature.Action)
        case map(MapLegacyBridgeFeature.Action)
        case favorites(FavoritesLegacyBridgeFeature.Action)
        case profile(ProfileFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case logout
        }
    }
    
    @Reducer
    enum Path {
        case popupRequestManagement(PopupRequestManagementFlowFeature)
        case popupRequestManagementDetail(PopupRequestManagementDetailFeature)
        case homeComingPopupDetail(HomeComingPopupDetailDestinationFeature)
        case popupDetail(PopupDetailDestinationFeature)
        case reviewDetail(ReviewDetailDestinationFeature)
        case alert(AlertDestinationFeature)
        case profileSetting(ProfileSettingFeature)
        case notifications(NotificationDestinationFeature)
        case serviceTerms(ServiceTermsDestinationFeature)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.core.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.calendar, action: \.calendar) {
            CalendarLegacyBridgeFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapLegacyBridgeFeature()
        }
        Scope(state: \.favorites, action: \.favorites) {
            FavoritesLegacyBridgeFeature()
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
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
                return .none
                
            case .calendar(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
                return .none
                
            case .favorites(.delegate(.browsePopupsRequested)):
                state.core.selectedTab = .home
                return .none
                
            case .favorites(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
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
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
                return .none
                
            case .home,
                    .calendar,
                    .map,
                    .favorites,
                    .profile:
                return .none
                
            case .path(.element(let id, let action)):
                return reducePathAction(id: id, action: action, state: &state)
                
            case .path:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.core.path, action: \.path)
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
                .alert(.delegate(.pushPopupDetail(_, let popup))):
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

@Reducer
struct CalendarLegacyBridgeFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        
        init(sessionContext: SessionContext) {
            self.userUuid = sessionContext.userUuid
        }
    }
    
    enum Action: Equatable {
        case alertTapped
        case popupSelected(Popup)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .alertTapped:
                return .send(.delegate(.alertRequested))
            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct MapLegacyBridgeFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        
        init(sessionContext: SessionContext) {
            self.userUuid = sessionContext.userUuid
        }
    }
    
    enum Action: Equatable {
        case popupSelected(Popup)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case popupSelected(Popup)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct FavoritesLegacyBridgeFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        
        init(sessionContext: SessionContext) {
            self.userUuid = sessionContext.userUuid
        }
    }
    
    enum Action: Equatable {
        case alertTapped
        case popupSelected(Popup)
        case browsePopupsTapped
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
            case browsePopupsRequested
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .alertTapped:
                return .send(.delegate(.alertRequested))
            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))
            case .browsePopupsTapped:
                return .send(.delegate(.browsePopupsRequested))
            case .delegate:
                return .none
            }
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
struct PopupDetailDestinationFeature {
    @ObservableState
    struct State: Equatable {
        var content: PopupDetailFeatureReducer.State
        let isAdmin: Bool

        init(
            userUuid: String,
            popup: Popup,
            isAdmin: Bool
        ) {
            self.content = .init(
                userUuid: userUuid,
                popup: popup
            )
            self.isAdmin = isAdmin
        }
    }
    
    enum Action: Equatable {
        case content(PopupDetailFeatureReducer.Action)
        case relatedPopupSelected(String, Popup)
        case deactivateCompleted
        case reviewsTapped([Review])
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case pushPopupDetail(String, Popup)
            case showReviews([Review])
            case favoriteChanged(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
            case close
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.content, action: \.content) {
            PopupDetailFeatureReducer()
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
struct AlertDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let userUuid: String
    }
    
    enum Action: Equatable {
        case popupSelected(String, Popup)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case pushPopupDetail(String, Popup)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .popupSelected(let userUuid, let popup):
                return .send(.delegate(.pushPopupDetail(userUuid, popup)))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct ReviewDetailDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let reviews: [Review]
    }
    
    enum Action: Equatable {}
    
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}

@Reducer
struct NotificationDestinationFeature {
    @ObservableState
    struct State: Equatable {
        init() {}
    }
    
    enum Action: Equatable {}
    
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}

@Reducer
struct ServiceTermsDestinationFeature {
    @ObservableState
    struct State: Equatable {
        init() {}
    }
    
    enum Action: Equatable {}
    
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
