import ComposableArchitecture
import Domain
import SwiftUI

@Reducer
public struct HomeComingPopupDetailDestinationFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        var content: ComingPopupDetailFeature.State

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
        case content(ComingPopupDetailFeature.Action)
        case popupSelected(Popup)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case selectPopup(Popup)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.content, action: \.content) {
            ComingPopupDetailFeature()
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

