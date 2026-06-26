import ComposableArchitecture
import Domain
import HomeFeature

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
        var home: HomeRootFeature.State
        var path = StackState<Path.State>()

        init(session: SessionState) {
            guard let context = session.context else {
                preconditionFailure("Home core requires a logged in session.")
            }
            self.home = .init(
                userUuid: context.userUuid,
                nickname: context.nickname
            )
        }

        mutating func syncSession(_ session: SessionState) {
            guard let context = session.context else { return }
            home.syncUser(
                userUuid: context.userUuid,
                nickname: context.nickname
            )
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab
                && lhs.home == rhs.home
        }
    }

    @ObservableState
    struct State: Equatable {
        var session: SessionState
        var core: CoreState

        init(
            session: SessionState,
            core: CoreState? = nil
        ) {
            self.session = session
            self.core = core ?? .init(session: session)
            self.core.syncSession(session)
        }

        var calendar: CalendarTabFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }

        var map: MapTabFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }

        var favorites: FavoritesTabFeature.State {
            get { .init(sessionContext: sessionContext) }
            set {}
        }

        var profile: ProfileTabFeature.State {
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
        case home(HomeRootFeature.Action)
        case calendar(CalendarTabFeature.Action)
        case map(MapTabFeature.Action)
        case favorites(FavoritesTabFeature.Action)
        case profile(ProfileTabFeature.Action)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case logout
        }
    }

    @Reducer
    enum Path {
        case popupDetail(PopupDetailDestinationFeature)
        case reviewDetail(ReviewDetailDestinationFeature)
        case alert(AlertDestinationFeature)
        case profileSetting(ProfileSettingDestinationFeature)
        case notifications(NotificationDestinationFeature)
        case serviceTerms(ServiceTermsDestinationFeature)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.core.home, action: \.home) {
            HomeRootFeature()
        }
        Scope(state: \.calendar, action: \.calendar) {
            CalendarTabFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapTabFeature()
        }
        Scope(state: \.favorites, action: \.favorites) {
            FavoritesTabFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileTabFeature()
        }

        Reduce { state, action in
            switch action {
            case .selectedTabChanged(let tab):
                state.core.selectedTab = tab
                return .none

            case .home(.delegate(.popupSelected(let popup))),
                    .calendar(.delegate(.popupSelected(let popup))),
                    .favorites(.delegate(.popupSelected(let popup))),
                    .map(.delegate(.popupSelected(let popup))),
                    .profile(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none

            case .home(.delegate(.alertRequested)),
                    .calendar(.delegate(.alertRequested)),
                    .favorites(.delegate(.alertRequested)),
                    .profile(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
                return .none

            case .favorites(.delegate(.browsePopupsRequested)):
                state.core.selectedTab = .home
                return .none

            case .profile(.delegate(.profileSettingRequested(let nickname, let isAlerted))):
                state.core.path.append(
                    .profileSetting(
                        .init(
                            userUuid: state.currentUser.userUuid,
                            nickname: nickname,
                            isAlerted: isAlerted
                        )
                    )
                )
                return .none

            case .profile(.delegate(.notificationsRequested)):
                state.core.path.append(.notifications(.init()))
                return .none

            case .profile(.delegate(.serviceTermsRequested)):
                state.core.path.append(.serviceTerms(.init()))
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
        case .popupDetail(.delegate(.pushPopupDetail(_, let popup))),
                .alert(.delegate(.pushPopupDetail(_, let popup))):
            appendPopupDetail(popup, state: &state)
            return .none

        case .popupDetail(.delegate(.showReviews(let reviews))):
            state.core.path.append(.reviewDetail(.init(reviews: reviews)))
            return .none

        case .popupDetail(.delegate(.close)):
            state.core.path.pop(from: id)
            return .none

        case .profileSetting(.delegate(.logout)):
            return .send(.delegate(.logout))

        case .profileSetting(.delegate(.nicknameUpdated(let nickname))):
            state.session.user?.nickname = nickname
            state.core.syncSession(state.session)
            return .none

        default:
            return .none
        }
    }
}

@Reducer
struct CalendarTabFeature {
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
struct MapTabFeature {
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
struct FavoritesTabFeature {
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

@Reducer
struct ProfileTabFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        var nickname: String
        var isAlerted: Bool

        init(sessionContext: SessionContext) {
            self.userUuid = sessionContext.userUuid
            self.nickname = sessionContext.nickname
            self.isAlerted = sessionContext.isAlerted
        }
    }

    enum Action: Equatable {
        case alertTapped
        case popupSelected(Popup)
        case profileSettingTapped(nickname: String, isAlerted: Bool)
        case notificationsTapped
        case serviceTermsTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
            case profileSettingRequested(nickname: String, isAlerted: Bool)
            case notificationsRequested
            case serviceTermsRequested
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .alertTapped:
                return .send(.delegate(.alertRequested))
            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))
            case .profileSettingTapped(let nickname, let isAlerted):
                return .send(.delegate(.profileSettingRequested(nickname: nickname, isAlerted: isAlerted)))
            case .notificationsTapped:
                return .send(.delegate(.notificationsRequested))
            case .serviceTermsTapped:
                return .send(.delegate(.serviceTermsRequested))
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
        let userUuid: String
        let popup: Popup
        let isAdmin: Bool
    }

    enum Action: Equatable {
        case relatedPopupSelected(String, Popup)
        case deactivateCompleted
        case reviewsTapped([Review])
        case delegate(Delegate)

        enum Delegate: Equatable {
            case pushPopupDetail(String, Popup)
            case showReviews([Review])
            case close
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
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
struct ProfileSettingDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let userUuid: String
        let nickname: String
        let isAlerted: Bool
    }

    enum Action: Equatable {
        case logoutTapped
        case nicknameUpdated(String)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case logout
            case nicknameUpdated(String)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .logoutTapped:
                return .send(.delegate(.logout))
            case .nicknameUpdated(let nickname):
                return .send(.delegate(.nicknameUpdated(nickname)))
            case .delegate:
                return .none
            }
        }
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
