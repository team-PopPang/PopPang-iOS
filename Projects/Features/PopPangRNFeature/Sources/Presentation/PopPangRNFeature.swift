import ComposableArchitecture
import Foundation

@Reducer
public struct PopPangRNFeature {
    public enum Screen: String, Equatable, Sendable {
        case popupRequest = "request"
        case popupRequestManagement = "request-management"
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
        /// 제보를 등록하고 완료 알림의 확인을 눌렀다 (RN 이벤트 `popupRequestSubmitted`).
        case popupRequestSubmitted
        /// RN 화면이 닫기를 요청했다 (뒤로가기, Nativepiece 표준 닫기).
        case closeRequested
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
            case .popupRequestSubmitted:
                guard state.screen == .popupRequest else { return .none }
                return .send(.delegate(.dismiss))

            case .closeRequested:
                switch state.screen {
                case .popupRequest:
                    return .send(.delegate(.dismiss))
                case .popupRequestManagement:
                    return .send(.delegate(.pop))
                }

            case .delegate:
                return .none
            }
        }
    }
}
