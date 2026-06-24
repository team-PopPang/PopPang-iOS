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
        var home: HomeFeatureReducer.State
        var path = StackState<Path.State>()
        @Presents var destination: Destination.State?

        init(currentUser: User) {
            self.home = .init(
                userUuid: currentUser.userUuid,
                nickname: currentUser.displayNickname
            )
        }

        mutating func syncCurrentUser(_ user: User) {
            home.syncUser(
                userUuid: user.userUuid,
                nickname: user.displayNickname
            )
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab
                && lhs.home == rhs.home
        }
    }

    @ObservableState
    struct State: Equatable {
        var currentUser: User
        var core: CoreState

        init(
            currentUser: User,
            core: CoreState? = nil
        ) {
            self.currentUser = currentUser
            self.core = core ?? .init(currentUser: currentUser)
            self.core.syncCurrentUser(currentUser)
        }

        var calendar: CalendarTabFeature.State {
            get { .init(currentUser: currentUser) }
            set {}
        }

        var map: MapTabFeature.State {
            get { .init(currentUser: currentUser) }
            set {}
        }

        var favorites: FavoritesTabFeature.State {
            get { .init(currentUser: currentUser) }
            set {}
        }

        var profile: ProfileTabFeature.State {
            get { .init(currentUser: currentUser) }
            set {}
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            MainTabCurrentUserSnapshot(lhs.currentUser) == MainTabCurrentUserSnapshot(rhs.currentUser)
                && lhs.core == rhs.core
        }
    }

    enum Action {
        case selectedTabChanged(MainTab)
        case home(HomeFeatureReducer.Action)
        case homeNavigation(HomeNavigationAction)
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

        enum HomeNavigationAction: Equatable {
            case popupSelected(Popup)
            case alertRequested
            case searchRequested
            case comingPopupsRequested([Popup])
            case popupRequestRequested
            case popupRequestManagementRequested
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
        Scope(state: \.core.home, action: \.home) {
            HomeFeatureReducer()
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

            case .homeNavigation(.popupSelected(let popup)),
                    .calendar(.delegate(.popupSelected(let popup))),
                    .favorites(.delegate(.popupSelected(let popup))),
                    .map(.delegate(.popupSelected(let popup))),
                    .profile(.delegate(.popupSelected(let popup))):
                appendPopupDetail(popup, state: &state)
                return .none

            case .homeNavigation(.alertRequested),
                    .calendar(.delegate(.alertRequested)),
                    .favorites(.delegate(.alertRequested)),
                    .profile(.delegate(.alertRequested)):
                state.core.path.append(.alert(.init(userUuid: state.currentUser.userUuid)))
                return .none

            case .homeNavigation(.searchRequested):
                state.core.destination = .search(
                    .init(
                        userUuid: state.currentUser.userUuid,
                        nickname: state.currentUser.displayNickname
                    )
                )
                return .none

            case .homeNavigation(.comingPopupsRequested(let popups)):
                state.core.path.append(
                    .comingPopupDetail(
                        .init(
                            userUuid: state.currentUser.userUuid,
                            popups: popups
                        )
                    )
                )
                return .none

            case .homeNavigation(.popupRequestRequested):
                state.core.path.append(.popupRequest(.init(userUuid: state.currentUser.userUuid)))
                return .none

            case .homeNavigation(.popupRequestManagementRequested):
                state.core.path.append(.popupRequestManagement(.init()))
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
                    .homeNavigation,
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
                state.core.destination = nil
                return .none

            case .destination(.presented(.search(.delegate(.selectPopup(let popup))))):
                state.core.destination = nil
                appendPopupDetail(popup, state: &state)
                return .none

            case .destination:
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
        case .popupDetail(.delegate(.pushPopupDetail(_, let popup))),
                .comingPopupDetail(.delegate(.pushPopupDetail(_, let popup))),
                .alert(.delegate(.pushPopupDetail(_, let popup))):
            appendPopupDetail(popup, state: &state)
            return .none

        case .popupDetail(.delegate(.showReviews(let reviews))):
            state.core.path.append(.reviewDetail(.init(reviews: reviews)))
            return .none

        case .popupDetail(.delegate(.close)):
            state.core.path.pop(from: id)
            return .none

        case .popupRequest(.delegate(.dismiss)),
                .popupRequestManagement(.delegate(.back)),
                .popupRequestManagementDetail(.delegate(.back)):
            state.core.path.pop(from: id)
            return .none

        case .popupRequestManagement(.delegate(.showDetail(let submissionId))):
            state.core.path.append(
                .popupRequestManagementDetail(
                    .init(submissionId: submissionId)
                )
            )
            return .none

        case .profileSetting(.delegate(.logout)):
            return .send(.delegate(.logout))

        case .profileSetting(.delegate(.nicknameUpdated(let nickname))):
            state.currentUser.nickname = nickname
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

        init(currentUser: User) {
            self.userUuid = currentUser.userUuid
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

        init(currentUser: User) {
            self.userUuid = currentUser.userUuid
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

        init(currentUser: User) {
            self.userUuid = currentUser.userUuid
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

        init(currentUser: User) {
            self.userUuid = currentUser.userUuid
            self.nickname = currentUser.displayNickname
            self.isAlerted = currentUser.isAlerted
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

private struct MainTabCurrentUserSnapshot: Equatable {
    let userUuid: String
    let uid: String
    let provider: String
    let email: String?
    let nickname: String?
    let role: String
    let isAlerted: Bool
    let fcmToken: String?
    let alertKeywordList: [String]?
    let recommendList: [Int]?

    init(_ user: User) {
        userUuid = user.userUuid
        uid = user.uid
        provider = user.provider
        email = user.email
        nickname = user.nickname
        role = user.role
        isAlerted = user.isAlerted
        fcmToken = user.fcmToken
        alertKeywordList = user.alertKeywordList
        recommendList = user.recommendList
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
