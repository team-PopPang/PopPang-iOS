import ComposableArchitecture
import Foundation

@Reducer
public struct PopupRequestManagementFlowFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public let adminUuid: String
        public var list: PopupRequestManagementListFeature.State

        public var id: String { "popup-request-management-\(adminUuid)" }

        public init(adminUuid: String) {
            self.adminUuid = adminUuid
            self.list = .init(adminUuid: adminUuid)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.adminUuid == rhs.adminUuid
                && lhs.list == rhs.list
        }
    }

    public enum Action: Equatable {
        case list(PopupRequestManagementListFeature.Action)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case showDetail(Int)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.list(let lhsAction), .list(let rhsAction)):
                return lhsAction == rhsAction
            case (.delegate(let lhsDelegate), .delegate(let rhsDelegate)):
                return lhsDelegate == rhsDelegate
            default:
                return false
            }
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.list, action: \.list) {
            PopupRequestManagementListFeature()
        }

        Reduce { state, action in
            switch action {
            case .list(.delegate(.backRequested)):
                return .send(.delegate(.dismiss))

            case .list(.delegate(.submissionSelected(let submissionId))):
                return .send(.delegate(.showDetail(submissionId)))

            case .list,
                 .delegate:
                return .none
            }
        }
    }
}
