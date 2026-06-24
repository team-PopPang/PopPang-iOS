import ComposableArchitecture
import Coordinator
import Domain

@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: MainTab
        var session: MainTabSession
        var path = StackState<Path.State>()
        @Presents var search: SearchDestinationFeature.State?
        var logoutToken = 0

        init(
            selectedTab: MainTab = .home,
            session: MainTabSession
        ) {
            self.selectedTab = selectedTab
            self.session = session
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case path(StackActionOf<Path>)
        case search(PresentationAction<SearchDestinationFeature.Action>)
        case homePopupSelected(Popup)
        case homeAlertTapped
        case homeSearchTapped
        case homeComingTapped([Popup])
        case homeReportTapped
        case homeManagePopupRequestsTapped
        case calendarAlertTapped
        case calendarPopupSelected(Popup)
        case favoritesAlertTapped
        case favoritesPopupSelected(Popup)
        case favoritesBrowsePopupsTapped
        case mapPopupSelected(Popup)
        case profileAlertTapped
        case profileSettingTapped(nickname: String, isAlerted: Bool)
        case profileNotificationsTapped
        case profileServiceTermsTapped
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

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .homePopupSelected(let popup),
                    .calendarPopupSelected(let popup),
                    .favoritesPopupSelected(let popup),
                    .mapPopupSelected(let popup):
                state.path.append(
                    .popupDetail(
                        .init(
                            userUuid: state.session.userUuid,
                            popup: popup,
                            isAdmin: state.session.isAdmin
                        )
                    )
                )
                return .none

            case .homeAlertTapped,
                    .calendarAlertTapped,
                    .favoritesAlertTapped,
                    .profileAlertTapped:
                state.path.append(.alert(.init(userUuid: state.session.userUuid)))
                return .none

            case .homeSearchTapped:
                state.search = .init(
                    userUuid: state.session.userUuid,
                    nickname: state.session.nickname
                )
                return .none

            case .homeComingTapped(let popups):
                state.path.append(
                    .comingPopupDetail(
                        .init(
                            userUuid: state.session.userUuid,
                            popups: popups
                        )
                    )
                )
                return .none

            case .homeReportTapped:
                state.path.append(.popupRequest(.init(userUuid: state.session.userUuid)))
                return .none

            case .homeManagePopupRequestsTapped:
                state.path.append(.popupRequestManagement(.init()))
                return .none

            case .favoritesBrowsePopupsTapped:
                state.selectedTab = .home
                return .none

            case .profileSettingTapped(let nickname, let isAlerted):
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

            case .profileNotificationsTapped:
                state.path.append(.notifications(.init()))
                return .none

            case .profileServiceTermsTapped:
                state.path.append(.serviceTerms(.init()))
                return .none

            case .path(.element(let id, let action)):
                switch action {
                case .popupDetail(.delegate(.pushPopupDetail(let userUuid, let popup))):
                    state.path.append(
                        .popupDetail(
                            .init(
                                userUuid: userUuid,
                                popup: popup,
                                isAdmin: state.session.isAdmin
                            )
                        )
                    )
                    return .none

                case .popupDetail(.delegate(.showReviews(let reviews))):
                    state.path.append(.reviewDetail(.init(reviews: reviews)))
                    return .none

                case .popupDetail(.delegate(.close)):
                    state.path.pop(from: id)
                    return .none

                case .comingPopupDetail(.delegate(.pushPopupDetail(let userUuid, let popup))):
                    state.path.append(
                        .popupDetail(
                            .init(
                                userUuid: userUuid,
                                popup: popup,
                                isAdmin: state.session.isAdmin
                            )
                        )
                    )
                    return .none

                case .alert(.delegate(.pushPopupDetail(let userUuid, let popup))):
                    state.path.append(
                        .popupDetail(
                            .init(
                                userUuid: userUuid,
                                popup: popup,
                                isAdmin: state.session.isAdmin
                            )
                        )
                    )
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
                    state.logoutToken += 1
                    return .none

                case .profileSetting(.delegate(.nicknameUpdated(let nickname))):
                    state.session.nickname = nickname
                    return .none

                default:
                    return .none
                }

            case .path:
                return .none

            case .search(.presented(.delegate(.dismiss))):
                state.search = nil
                return .none

            case .search(.presented(.delegate(.selectPopup(let popup)))):
                let userUuid = state.session.userUuid
                state.search = nil
                state.path.append(
                    .popupDetail(
                        .init(
                            userUuid: userUuid,
                            popup: popup,
                            isAdmin: state.session.isAdmin
                        )
                    )
                )
                return .none

            case .search:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$search, action: \.search) {
            SearchDestinationFeature()
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
