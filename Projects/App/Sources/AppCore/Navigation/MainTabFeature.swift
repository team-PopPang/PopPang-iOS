import ComposableArchitecture
import Domain

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

struct MainTabSession: Equatable, Hashable, Sendable {
    var userUuid: String
    var nickname: String
    var isAlerted: Bool
    var role: String

    init(
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

    var isAdmin: Bool {
        role.uppercased() == "ADMIN"
    }
}

@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: MainTab
        var session: MainTabSession
        var home: HomeTabFeature.State
        var calendar: CalendarTabFeature.State
        var map: MapTabFeature.State
        var favorites: FavoritesTabFeature.State
        var profile: ProfileTabFeature.State
        var path = StackState<Path.State>()
        @Presents var destination: Destination.State?

        init(
            selectedTab: MainTab = .home,
            session: MainTabSession
        ) {
            self.selectedTab = selectedTab
            self.session = session
            self.home = HomeTabFeature.State(session: session)
            self.calendar = CalendarTabFeature.State(session: session)
            self.map = MapTabFeature.State(session: session)
            self.favorites = FavoritesTabFeature.State(session: session)
            self.profile = ProfileTabFeature.State(session: session)
        }

        mutating func updateSession(_ session: MainTabSession) {
            self.session = session
            home.updateSession(session)
            calendar.updateSession(session)
            map.updateSession(session)
            favorites.updateSession(session)
            profile.updateSession(session)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab
                && lhs.session == rhs.session
                && lhs.home == rhs.home
                && lhs.calendar == rhs.calendar
                && lhs.map == rhs.map
                && lhs.favorites == rhs.favorites
                && lhs.profile == rhs.profile
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case home(HomeTabFeature.Action)
        case calendar(CalendarTabFeature.Action)
        case map(MapTabFeature.Action)
        case favorites(FavoritesTabFeature.Action)
        case profile(ProfileTabFeature.Action)
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case logout
        }
    }

    @Reducer
    enum Path {
        case popupDetail(PopupDetailDestinationFeature)
        case comingPopupDetail(ComingPopupDetailDestinationFeature)
        case reviewDetail(ReviewDetailDestinationFeature)
        case alert(AlertDestinationFeature)
        case popupRequest(PopupRequestDestinationFeature)
        case popupRequestManagement(PopupRequestManagementDestinationFeature)
        case popupRequestManagementDetail(PopupRequestManagementDetailDestinationFeature)
        case profileSetting(ProfileSettingDestinationFeature)
        case notifications(NotificationDestinationFeature)
        case serviceTerms(ServiceTermsDestinationFeature)
    }

    @Reducer
    enum Destination {
        case search(SearchDestinationFeature)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.home, action: \.home) {
            HomeTabFeature()
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
            case .binding:
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
                state.path.append(.alert(.init(userUuid: state.session.userUuid)))
                return .none

            case .home(.delegate(.searchRequested)):
                state.destination = .search(
                    .init(
                        userUuid: state.session.userUuid,
                        nickname: state.session.nickname
                    )
                )
                return .none

            case .home(.delegate(.comingPopupsRequested(let popups))):
                state.path.append(
                    .comingPopupDetail(
                        .init(
                            userUuid: state.session.userUuid,
                            popups: popups
                        )
                    )
                )
                return .none

            case .home(.delegate(.popupRequestRequested)):
                state.path.append(.popupRequest(.init(userUuid: state.session.userUuid)))
                return .none

            case .home(.delegate(.popupRequestManagementRequested)):
                state.path.append(.popupRequestManagement(.init()))
                return .none

            case .favorites(.delegate(.browsePopupsRequested)):
                state.selectedTab = .home
                return .none

            case .profile(.delegate(.profileSettingRequested(let nickname, let isAlerted))):
                state.path.append(
                    .profileSetting(
                        .init(
                            userUuid: state.session.userUuid,
                            nickname: nickname,
                            isAlerted: isAlerted
                        )
                    )
                )
                return .none

            case .profile(.delegate(.notificationsRequested)):
                state.path.append(.notifications(.init()))
                return .none

            case .profile(.delegate(.serviceTermsRequested)):
                state.path.append(.serviceTerms(.init()))
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

            case .destination(.presented(.search(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case .destination(.presented(.search(.delegate(.selectPopup(let popup))))):
                state.destination = nil
                appendPopupDetail(popup, state: &state)
                return .none

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
}

private extension MainTabFeature {
    func appendPopupDetail(_ popup: Popup, state: inout State) {
        state.path.append(
            .popupDetail(
                .init(
                    userUuid: state.session.userUuid,
                    popup: popup,
                    isAdmin: state.session.isAdmin
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
                .comingPopupDetail(.delegate(.pushPopupDetail(_, let popup))),
                .alert(.delegate(.pushPopupDetail(_, let popup))):
            appendPopupDetail(popup, state: &state)
            return .none

        case .popupDetail(.delegate(.showReviews(let reviews))):
            state.path.append(.reviewDetail(.init(reviews: reviews)))
            return .none

        case .popupDetail(.delegate(.close)):
            state.path.pop(from: id)
            return .none

        case .popupRequest(.delegate(.dismiss)),
                .popupRequestManagement(.delegate(.back)),
                .popupRequestManagementDetail(.delegate(.back)):
            state.path.pop(from: id)
            return .none

        case .popupRequestManagement(.delegate(.showDetail(let submissionId))):
            state.path.append(
                .popupRequestManagementDetail(
                    .init(submissionId: submissionId)
                )
            )
            return .none

        case .profileSetting(.delegate(.logout)):
            return .send(.delegate(.logout))

        case .profileSetting(.delegate(.nicknameUpdated(let nickname))):
            var nextSession = state.session
            nextSession.nickname = nickname
            state.updateSession(nextSession)
            return .none

        default:
            return .none
        }
    }
}

@Reducer
struct HomeTabFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        var nickname: String
        var isAdmin: Bool

        init(session: MainTabSession) {
            self.userUuid = session.userUuid
            self.nickname = session.nickname
            self.isAdmin = session.isAdmin
        }

        mutating func updateSession(_ session: MainTabSession) {
            userUuid = session.userUuid
            nickname = session.nickname
            isAdmin = session.isAdmin
        }
    }

    enum Action: Equatable {
        case popupSelected(Popup)
        case alertTapped
        case searchTapped
        case comingPopupsTapped([Popup])
        case popupRequestTapped
        case popupRequestManagementTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case popupSelected(Popup)
            case alertRequested
            case searchRequested
            case comingPopupsRequested([Popup])
            case popupRequestRequested
            case popupRequestManagementRequested
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))
            case .alertTapped:
                return .send(.delegate(.alertRequested))
            case .searchTapped:
                return .send(.delegate(.searchRequested))
            case .comingPopupsTapped(let popups):
                return .send(.delegate(.comingPopupsRequested(popups)))
            case .popupRequestTapped:
                return .send(.delegate(.popupRequestRequested))
            case .popupRequestManagementTapped:
                return .send(.delegate(.popupRequestManagementRequested))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct CalendarTabFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String

        init(session: MainTabSession) {
            self.userUuid = session.userUuid
        }

        mutating func updateSession(_ session: MainTabSession) {
            userUuid = session.userUuid
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

        init(session: MainTabSession) {
            self.userUuid = session.userUuid
        }

        mutating func updateSession(_ session: MainTabSession) {
            userUuid = session.userUuid
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

        init(session: MainTabSession) {
            self.userUuid = session.userUuid
        }

        mutating func updateSession(_ session: MainTabSession) {
            userUuid = session.userUuid
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

        init(session: MainTabSession) {
            self.userUuid = session.userUuid
            self.nickname = session.nickname
            self.isAlerted = session.isAlerted
        }

        mutating func updateSession(_ session: MainTabSession) {
            userUuid = session.userUuid
            nickname = session.nickname
            isAlerted = session.isAlerted
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

@Reducer
struct SearchDestinationFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        let userUuid: String
        let nickname: String

        var id: String { "search-\(userUuid)" }
    }

    enum Action: Equatable {
        case dismissTapped
        case popupSelected(Popup)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismiss
            case selectPopup(Popup)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismissTapped:
                return .send(.delegate(.dismiss))
            case .popupSelected(let popup):
                return .send(.delegate(.selectPopup(popup)))
            case .delegate:
                return .none
            }
        }
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
struct ComingPopupDetailDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let userUuid: String
        let popups: [Popup]
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
struct PopupRequestDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let userUuid: String
    }

    enum Action: Equatable {
        case dismissTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismiss
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismissTapped:
                return .send(.delegate(.dismiss))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct PopupRequestManagementDestinationFeature {
    @ObservableState
    struct State: Equatable {
        init() {}
    }

    enum Action: Equatable {
        case backTapped
        case submissionSelected(String)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
            case showDetail(String)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.back))
            case .submissionSelected(let submissionId):
                return .send(.delegate(.showDetail(submissionId)))
            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
struct PopupRequestManagementDetailDestinationFeature {
    @ObservableState
    struct State: Equatable {
        let submissionId: String
    }

    enum Action: Equatable {
        case backTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.back))
            case .delegate:
                return .none
            }
        }
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
