import ComposableArchitecture
import Domain
import SearchFeature
import SwiftUI

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

public struct HomeSearchDestinationView: View {
    let store: StoreOf<HomeSearchDestinationFeature>

    public init(store: StoreOf<HomeSearchDestinationFeature>) {
        self.store = store
    }

    public var body: some View {
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
        var content: ComingPopupDetailReducer.State

        public var id: String { "home-coming-\(content.userUuid)" }

        public init(
            userUuid: String,
            popups: [Popup]
        ) {
            self.content = .init(
                userUuid: userUuid,
                popups: popups
            )
        }
    }

    public enum Action: Equatable {
        case content(ComingPopupDetailReducer.Action)
        case popupSelected(Popup)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case selectPopup(Popup)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.content, action: \.content) {
            ComingPopupDetailReducer()
        }

        Reduce { _, action in
            switch action {
            case .content:
                return .none
            case .popupSelected(let popup):
                return .send(.delegate(.selectPopup(popup)))
            case .delegate:
                return .none
            }
        }
    }
}

public struct HomeComingPopupDetailDestinationView: View {
    let store: StoreOf<HomeComingPopupDetailDestinationFeature>

    public init(store: StoreOf<HomeComingPopupDetailDestinationFeature>) {
        self.store = store
    }

    public var body: some View {
        ComingPopupDetailFeatureView(
            store: store.scope(state: \.content, action: \.content),
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}
