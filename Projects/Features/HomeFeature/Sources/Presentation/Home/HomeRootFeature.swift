import ComposableArchitecture
import Domain
import PopupRequestFeature
import PopupRequestManagementFeature
import SearchFeature
import SwiftUI

@Reducer
public struct HomeRootFeature {
    @Reducer
    public enum Destination {
        case search(HomeSearchDestinationFeature)
        case comingPopupDetail(HomeComingPopupDetailDestinationFeature)
        case popupRequest(HomePopupRequestDestinationFeature)
        case popupRequestManagement(HomePopupRequestManagementFlowFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var content: HomeFeatureReducer.State
        @Presents var destination: Destination.State?

        public init(
            userUuid: String,
            nickname: String,
            isAdmin: Bool
        ) {
            self.content = .init(
                userUuid: userUuid,
                nickname: nickname,
                isAdmin: isAdmin
            )
        }

        public mutating func syncUser(
            userUuid: String,
            nickname: String,
            isAdmin: Bool
        ) {
            content.syncUser(
                userUuid: userUuid,
                nickname: nickname,
                isAdmin: isAdmin
            )
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.content == rhs.content
                && destinationsEqual(lhs.destination, rhs.destination)
        }

        private static func destinationsEqual(
            _ lhs: Destination.State?,
            _ rhs: Destination.State?
        ) -> Bool {
            switch (lhs, rhs) {
            case (.search(let lhsState), .search(let rhsState)):
                lhsState == rhsState
            case (.comingPopupDetail(let lhsState), .comingPopupDetail(let rhsState)):
                lhsState == rhsState
            case (.popupRequest(let lhsState), .popupRequest(let rhsState)):
                lhsState == rhsState
            case (.popupRequestManagement(let lhsState), .popupRequestManagement(let rhsState)):
                lhsState == rhsState
            case (nil, nil):
                true
            default:
                false
            }
        }
    }

    public enum Action {
        case content(HomeFeatureReducer.Action)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case popupSelected(Popup)
            case alertRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.content, action: \.content) {
            HomeFeatureReducer()
        }

        Reduce { state, action in
            switch action {
            case .content(.delegate(.popupSelected(let popup))):
                return .send(.delegate(.popupSelected(popup)))

            case .content(.delegate(.alertRequested)):
                return .send(.delegate(.alertRequested))

            case .content(.delegate(.searchRequested)):
                state.destination = .search(
                    .init(
                        userUuid: state.content.userUuid,
                        nickname: state.content.nickname
                    )
                )
                return .none

            case .content(.delegate(.comingPopupsRequested(let popups))):
                state.destination = .comingPopupDetail(
                    .init(
                        userUuid: state.content.userUuid,
                        popups: popups
                    )
                )
                return .none

            case .content(.delegate(.popupRequestRequested)):
                state.destination = .popupRequest(
                    .init(userUuid: state.content.userUuid)
                )
                return .none

            case .content(.delegate(.popupRequestManagementRequested)):
                state.destination = .popupRequestManagement(.init())
                return .none

            case .destination(.presented(.search(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case .destination(.presented(.search(.delegate(.selectPopup(let popup))))):
                state.destination = nil
                return .send(.delegate(.popupSelected(popup)))

            case .destination(.presented(.comingPopupDetail(.delegate(.selectPopup(let popup))))):
                return .send(.delegate(.popupSelected(popup)))

            case .destination(.presented(.popupRequest(.delegate(.dismiss)))),
                    .destination(.presented(.popupRequestManagement(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case .content,
                    .destination,
                    .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

public struct HomeRootFeatureView: View {
    @Bindable var store: StoreOf<HomeRootFeature>

    public init(store: StoreOf<HomeRootFeature>) {
        self.store = store
    }

    public var body: some View {
        HomeFeatureView(store: store.scope(state: \.content, action: \.content))
        .fullScreenCover(
            item: $store.scope(state: \.destination?.search, action: \.destination.search)
        ) { store in
            HomeSearchDestinationView(store: store)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.comingPopupDetail, action: \.destination.comingPopupDetail)
        ) { store in
            HomeComingPopupDetailDestinationView(store: store)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.popupRequest, action: \.destination.popupRequest)
        ) { store in
            HomePopupRequestDestinationView(store: store)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.popupRequestManagement, action: \.destination.popupRequestManagement)
        ) { store in
            HomePopupRequestManagementFlowView(store: store)
        }
    }
}

@Reducer
public struct HomeSearchDestinationFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        let userUuid: String
        let nickname: String

        public var id: String { "home-search-\(userUuid)" }

        public init(
            userUuid: String,
            nickname: String
        ) {
            self.userUuid = userUuid
            self.nickname = nickname
        }
    }

    public enum Action: Equatable {
        case dismissTapped
        case popupSelected(Popup)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case selectPopup(Popup)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
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

private struct HomeSearchDestinationView: View {
    let store: StoreOf<HomeSearchDestinationFeature>

    var body: some View {
        SearchFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            onDismiss: {
                store.send(.dismissTapped)
            },
            onSelectPopup: { popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}

@Reducer
public struct HomeComingPopupDetailDestinationFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        let userUuid: String
        let popups: [Popup]

        public var id: String { "home-coming-\(userUuid)" }

        public init(
            userUuid: String,
            popups: [Popup]
        ) {
            self.userUuid = userUuid
            self.popups = popups
        }
    }

    public enum Action: Equatable {
        case popupSelected(Popup)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case selectPopup(Popup)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .popupSelected(let popup):
                return .send(.delegate(.selectPopup(popup)))
            case .delegate:
                return .none
            }
        }
    }
}

private struct HomeComingPopupDetailDestinationView: View {
    let store: StoreOf<HomeComingPopupDetailDestinationFeature>

    var body: some View {
        ComingPopupDetailFeatureView(
            userUuid: store.userUuid,
            popups: store.popups,
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}

@Reducer
public struct HomePopupRequestDestinationFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        let userUuid: String

        public var id: String { "home-popup-request-\(userUuid)" }

        public init(userUuid: String) {
            self.userUuid = userUuid
        }
    }

    public enum Action: Equatable {
        case dismissTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
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

private struct HomePopupRequestDestinationView: View {
    let store: StoreOf<HomePopupRequestDestinationFeature>

    var body: some View {
        PopupRequestFeatureView(
            userUuid: store.userUuid,
            onDismiss: {
                store.send(.dismissTapped)
            }
        )
    }
}

@Reducer
public struct HomePopupRequestManagementFlowFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        var detailSubmissionId: String?

        public var id: String { "home-popup-request-management" }

        public init(detailSubmissionId: String? = nil) {
            self.detailSubmissionId = detailSubmissionId
        }
    }

    public enum Action: Equatable {
        case backTapped
        case submissionSelected(String)
        case detailDismissed
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.dismiss))
            case .submissionSelected(let submissionId):
                state.detailSubmissionId = submissionId
                return .none
            case .detailDismissed:
                state.detailSubmissionId = nil
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

private struct HomePopupRequestManagementFlowView: View {
    @Bindable var store: StoreOf<HomePopupRequestManagementFlowFeature>

    var body: some View {
        PopupRequestManagementFeatureView(
            onBack: {
                store.send(.backTapped)
            },
            onSelectSubmission: { submissionId in
                store.send(.submissionSelected(submissionId))
            }
        )
        .navigationDestination(
            isPresented: Binding(
                get: { store.detailSubmissionId != nil },
                set: { isPresented in
                    if !isPresented {
                        store.send(.detailDismissed)
                    }
                }
            )
        ) {
            if let submissionId = store.detailSubmissionId {
                PopupRequestManagementDetailFeatureView(
                    submissionId: submissionId,
                    onBack: {
                        store.send(.detailDismissed)
                    }
                )
            }
        }
    }
}
