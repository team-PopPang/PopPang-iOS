import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct PopupRequestManagementListFeature {
    @ObservableState
    public struct State: Equatable {
        public let adminUuid: String
        public var allItems: [PopupRequestManagementListItem] = []
        public var selectedFilter: PopupRequestManagementFilter = .all
        public var isLoading = false
        public var hasLoaded = false
        public var errorMessage: String?

        public init(adminUuid: String) {
            self.adminUuid = adminUuid
        }

        var filteredItems: [PopupRequestManagementListItem] {
            guard let status = selectedFilter.status else { return allItems }
            return allItems.filter { $0.status == status }
        }

        var pendingCount: Int { allItems.filter { $0.status == .pending }.count }
        var approvedCount: Int { allItems.filter { $0.status == .approved }.count }
        var rejectedCount: Int { allItems.filter { $0.status == .rejected }.count }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case backTapped
        case filterSelected(PopupRequestManagementFilter)
        case submissionTapped(Int)
        case submissionsLoaded([PopupRequestManagementListItem])
        case submissionsFailed(String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case backRequested
            case submissionSelected(Int)
        }
    }

    @Dependencies.Dependency(\.popupRequestManagementClient) private var popupRequestManagementClient: PopupRequestManagementClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoaded == false else { return .none }
                state.hasLoaded = true
                state.isLoading = true
                state.errorMessage = nil
                return loadList(adminUuid: state.adminUuid)

            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                return loadList(adminUuid: state.adminUuid)

            case .backTapped:
                return .send(.delegate(.backRequested))

            case .filterSelected(let filter):
                state.selectedFilter = filter
                return .none

            case .submissionTapped(let submissionId):
                return .send(.delegate(.submissionSelected(submissionId)))

            case .submissionsLoaded(let items):
                state.isLoading = false
                state.allItems = items
                state.errorMessage = nil
                return .none

            case .submissionsFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension PopupRequestManagementListFeature {
    func loadList(adminUuid: String) -> Effect<Action> {
        let popupRequestManagementClient = popupRequestManagementClient

        return .run { [popupRequestManagementClient, adminUuid] send in
            do {
                let items = try await popupRequestManagementClient.getPopupSubmissionList(adminUuid, .all)
                    .map(PopupRequestManagementListItem.init(item:))
                await send(.submissionsLoaded(items))
            } catch {
                await send(.submissionsFailed(error.localizedDescription))
            }
        }
    }
}
