import ComposableArchitecture
import Foundation

@Reducer
public struct PopPangRNFeature {
    public enum Screen: String, Equatable, Sendable {
        case popupRequest = "request"
        case popupRequestManagement = "request-management"

        var nativeEvents: [String] {
            switch self {
            case .popupRequest:
                [
                    PopPangRNEvent.popupRequestSubmitted,
                    PopPangRNEvent.popupRequestBack,
                ]
            case .popupRequestManagement:
                [PopPangRNEvent.popupRequestManagementBack]
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Identifiable {
        public let screen: Screen
        public let userUuid: String

        public var id: String { "\(screen.rawValue)-\(userUuid)" }

        public init(
            screen: Screen,
            userUuid: String
        ) {
            self.screen = screen
            self.userUuid = userUuid
        }
    }

    public enum Action: Equatable {
        case nativeEventReceived(String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case pop
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nativeEventReceived(let eventName):
                switch (state.screen, eventName) {
                case (.popupRequest, PopPangRNEvent.popupRequestSubmitted),
                     (.popupRequest, PopPangRNEvent.popupRequestBack):
                    return .send(.delegate(.dismiss))

                case (.popupRequestManagement, PopPangRNEvent.popupRequestManagementBack):
                    return .send(.delegate(.pop))

                default:
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }
}

private enum PopPangRNEvent {
    static let popupRequestSubmitted = "popupRequestSubmitted"
    static let popupRequestBack = "popupRequestBack"
    static let popupRequestManagementBack = "popupRequestManagementBack"
}
