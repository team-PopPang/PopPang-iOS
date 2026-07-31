import ComposableArchitecture
import Foundation

@Reducer
struct PopupPaginationDemoFeature {
    @ObservableState
    struct State: Equatable {
        var userUuid: String
        var items: [PopupPaginationItem] = []
        var nextCursor: Int64?
        var hasNext = true
        var loadedPageCount = 0
        var isInitialLoading = false
        var isLoadingNextPage = false
        var hasStarted = false
        var errorMessage: String?

        init(userUuid: String = "") {
            self.userUuid = userUuid
        }

        var isRequesting: Bool {
            isInitialLoading || isLoadingNextPage
        }

        var canStart: Bool {
            !userUuid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !isRequesting
        }
    }

    enum Action: Equatable {
        case task
        case retryTapped
        case reachedEnd
        case pageLoaded(
            userUuid: String,
            requestedCursor: Int64?,
            page: PopupPaginationPage
        )
        case pageFailed(
            userUuid: String,
            requestedCursor: Int64?,
            message: String
        )
    }

    @Dependency(\.popupPaginationClient) private var paginationClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.hasStarted, state.canStart else { return .none }
                return startInitialLoad(state: &state)

            case .retryTapped:
                guard !state.isRequesting else { return .none }

                if state.items.isEmpty {
                    return startInitialLoad(state: &state)
                }

                guard state.hasNext, let cursor = state.nextCursor else {
                    return .none
                }
                state.errorMessage = nil
                state.isLoadingNextPage = true
                return requestPage(
                    userUuid: state.userUuid,
                    cursor: cursor
                )

            case .reachedEnd:
                guard state.hasStarted,
                      state.hasNext,
                      !state.isRequesting,
                      state.errorMessage == nil,
                      let cursor = state.nextCursor
                else {
                    return .none
                }

                state.isLoadingNextPage = true
                return requestPage(
                    userUuid: state.userUuid,
                    cursor: cursor
                )

            case let .pageLoaded(userUuid, requestedCursor, page):
                guard userUuid == state.userUuid else { return .none }

                state.isInitialLoading = false
                state.isLoadingNextPage = false
                state.errorMessage = nil
                state.loadedPageCount += 1

                if requestedCursor == nil {
                    state.items = page.items.removingDuplicatePopupUuids()
                } else {
                    state.items.appendUniquePopups(page.items)
                }

                state.nextCursor = page.nextCursor
                state.hasNext = page.hasNext

                if page.hasNext, page.nextCursor == nil {
                    state.hasNext = false
                    state.errorMessage = "다음 페이지가 있지만 nextCursor가 비어 있습니다."
                }

                return .none

            case let .pageFailed(userUuid, _, message):
                guard userUuid == state.userUuid else { return .none }

                state.isInitialLoading = false
                state.isLoadingNextPage = false
                state.errorMessage = message
                return .none
            }
        }
    }
}

private extension PopupPaginationDemoFeature {
    func startInitialLoad(state: inout State) -> Effect<Action> {
        let userUuid = state.userUuid.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !userUuid.isEmpty else { return .none }

        state.userUuid = userUuid
        state.items = []
        state.nextCursor = nil
        state.hasNext = true
        state.loadedPageCount = 0
        state.isInitialLoading = true
        state.isLoadingNextPage = false
        state.hasStarted = true
        state.errorMessage = nil

        return requestPage(userUuid: userUuid, cursor: nil)
    }

    func requestPage(
        userUuid: String,
        cursor: Int64?
    ) -> Effect<Action> {
        let paginationClient = paginationClient

        return .run { send in
            do {
                let page = try await paginationClient.fetchPage(userUuid, cursor)
                await send(.pageLoaded(
                    userUuid: userUuid,
                    requestedCursor: cursor,
                    page: page
                ))
            } catch {
                await send(.pageFailed(
                    userUuid: userUuid,
                    requestedCursor: cursor,
                    message: error.localizedDescription
                ))
            }
        }
    }
}

private extension Array where Element == PopupPaginationItem {
    func removingDuplicatePopupUuids() -> Self {
        var popupUuids = Set<String>()
        return filter { popupUuids.insert($0.popupUuid).inserted }
    }

    mutating func appendUniquePopups(_ newItems: Self) {
        var popupUuids = Set(map(\.popupUuid))
        append(contentsOf: newItems.filter {
            popupUuids.insert($0.popupUuid).inserted
        })
    }
}
