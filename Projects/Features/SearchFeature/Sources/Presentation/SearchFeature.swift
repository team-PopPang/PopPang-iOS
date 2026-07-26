import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct SearchFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        // public var id: String { "search-\(userUuid)" }
        public let id = UUID()
        public let userUuid: String
        public let nickname: String
        public var searchText = ""
        public var recentKeywords: [String] = []
        public var searchPopupList: [Popup] = []
        public var isLoading = false
        public var errorMessage: String?

        public init(
            userUuid: String = "demo-user",
            nickname: String = "홍길동"
        ) {
            self.userUuid = userUuid
            self.nickname = nickname
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.nickname == rhs.nickname
                && lhs.searchText == rhs.searchText
                && lhs.recentKeywords == rhs.recentKeywords
                && lhs.searchPopupList == rhs.searchPopupList
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case onAppear
        case dismissTapped
        case popupSelected(Popup)
        case searchTextChanged(String)
        case recentKeywordTapped(String)
        case recentKeywordRemoved(String)
        case recentKeywordsLoaded([String])
        case loadingChanged(Bool)
        case searchResponse(Result<SearchResponse, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case popupSelected(Popup)
        }
    }

    public struct SearchResponse: Sendable {
        let popups: [Popup]
        let recentKeywords: [String]?
    }

    @Dependency(\.searchFeatureClient) private var searchFeatureClient: SearchFeatureClient
    @Dependency(\.continuousClock) private var clock

    private enum CancelID {
        case search
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.recentKeywords = searchFeatureClient.loadRecentKeywords()
                return .none

            case .dismissTapped:
                state.isLoading = false
                return .merge(
                    .cancel(id: CancelID.search),
                    .send(.delegate(.dismiss))
                )

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .searchTextChanged(let searchText):
                
                // 검색어가 같으면 무시
                guard state.searchText != searchText else {
                    return .none
                }
                
                state.searchText = searchText

                guard searchText.isEmpty == false else {
                    state.searchPopupList = []
                    state.errorMessage = nil
                    state.isLoading = false
                    return .cancel(id: CancelID.search)
                }

                state.isLoading = false
                state.errorMessage = nil
                return search(
                    userUuid: state.userUuid,
                    searchText: searchText,
                    shouldPersistKeyword: true,
                    startsLoadingAfterDebounce: true
                )
          

            case .recentKeywordTapped(let keyword):
                state.searchText = keyword
                state.isLoading = true
                state.errorMessage = nil
                return search(
                    userUuid: state.userUuid,
                    searchText: keyword,
                    shouldPersistKeyword: false,
                    startsLoadingAfterDebounce: false
                )

            case .recentKeywordRemoved(let keyword):
                searchFeatureClient.removeRecentKeyword(keyword)
                state.recentKeywords = searchFeatureClient.loadRecentKeywords()
                return .none

            case .recentKeywordsLoaded(let recentKeywords):
                state.recentKeywords = recentKeywords
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .searchResponse(.success(let response)):
                state.searchPopupList = response.popups
                state.errorMessage = nil
                state.isLoading = false
                if let recentKeywords = response.recentKeywords {
                    state.recentKeywords = recentKeywords
                }
                return .none

            case .searchResponse(.failure(let error)):
                state.searchPopupList = []
                state.errorMessage = error.localizedDescription
                state.isLoading = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension SearchFeature {
    func search(
        userUuid: String,
        searchText: String,
        shouldPersistKeyword: Bool,
        startsLoadingAfterDebounce: Bool
    ) -> Effect<Action> {
        let searchFeatureClient = searchFeatureClient
        let clock = clock

        return .run { send in
            do {
                // debounce
                try await clock.sleep(for: .milliseconds(800))
                try Task.checkCancellation()

                if startsLoadingAfterDebounce {
                    await send(.loadingChanged(true))
                }

                let popups = try await searchFeatureClient.searchPopups(
                    userUuid,
                    searchText
                )
                try Task.checkCancellation()

                var recentKeywords: [String]?
                if shouldPersistKeyword {
                    try Task.checkCancellation()
                    searchFeatureClient.addRecentKeyword(searchText)
                    recentKeywords = searchFeatureClient.loadRecentKeywords()
                }

                await send(.searchResponse(.success(.init(
                    popups: popups,
                    recentKeywords: recentKeywords
                ))))
            } catch is CancellationError {
            } catch {
                await send(.searchResponse(.failure(error)))
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }
}
