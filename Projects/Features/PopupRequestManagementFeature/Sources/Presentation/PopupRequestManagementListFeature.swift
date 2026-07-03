import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct PopupRequestManagementListFeature {
    @ObservableState
    public struct State: Equatable {
        public let adminUuid: String
        public var allItems: [PopupRequestManagementListItem] = []
        public var items: [PopupRequestManagementListItem] = []
        public var selectedFilter: PopupRequestManagementFilter = .all
        public var isLoading = false
        public var hasLoaded = false
        public var errorMessage: String?

        public init(adminUuid: String) {
            self.adminUuid = adminUuid
        }

        var filteredItems: [PopupRequestManagementListItem] {
            items
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
        case submissionsLoaded(
            summaryItems: [PopupRequestManagementListItem],
            items: [PopupRequestManagementListItem]
        )
        case submissionsFailed(String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case backRequested
            case submissionSelected(Int)
        }
    }

    @Dependency(\.popupRequestManagementClient) private var popupRequestManagementClient: PopupRequestManagementClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoaded == false else { return .none }
                state.hasLoaded = true
                state.isLoading = true
                state.errorMessage = nil
                return loadList(
                    adminUuid: state.adminUuid,
                    filter: state.selectedFilter
                )

            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                return loadList(
                    adminUuid: state.adminUuid,
                    filter: state.selectedFilter
                )

            case .backTapped:
                return .send(.delegate(.backRequested))

            case .filterSelected(let filter):
                state.selectedFilter = filter
                state.isLoading = true
                state.errorMessage = nil
                return loadList(
                    adminUuid: state.adminUuid,
                    filter: filter
                )

            case .submissionTapped(let submissionId):
                return .send(.delegate(.submissionSelected(submissionId)))

            case let .submissionsLoaded(summaryItems, items):
                state.isLoading = false
                state.allItems = summaryItems
                state.items = items
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
    func loadList(
        adminUuid: String,
        filter: PopupRequestManagementFilter
    ) -> Effect<Action> {
        let popupRequestManagementClient = popupRequestManagementClient

        return .run { [popupRequestManagementClient, adminUuid, filter] send in
            do {
                async let summaryResponse = popupRequestManagementClient.getPopupSubmissionList(adminUuid, .all)
                async let filteredResponse = popupRequestManagementClient.getPopupSubmissionList(
                    adminUuid,
                    filter.domainFilter
                )

                let summaryItems = try await summaryResponse.map(PopupRequestManagementListItem.init(item:))
                let items = try await filteredResponse.map(PopupRequestManagementListItem.init(item:))

                await send(.submissionsLoaded(
                    summaryItems: summaryItems,
                    items: items
                ))
            } catch {
                await send(.submissionsFailed(error.localizedDescription))
            }
        }
    }
}
