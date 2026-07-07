import Compound
import Core
import Domain
import Foundation

@Compound
final class SearchFeatureCompound {
    enum Action {
        case onAppear
        case searchTextChanged(String)
        case recentKeywordTapped(String)
        case recentKeywordRemoved(String)
    }

    enum Reaction {
        case setRecentKeywords([String])
        case setSearchText(String)
        case setSearchResults([Popup])
        case setLoading(Bool)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var searchText = ""
        var recentKeywords: [String] = []
        var searchPopupList: [Popup] = []
        var isLoading = false
        var errorMessage: String?
    }

    var state = State()

    private let userUuid: String
    private let recentSearchStorage: RecentSearchStorage

    @Dependency private var popupUsecase: PopupUsecaseProtocol

    init(
        userUuid: String,
        recentSearchStorage: RecentSearchStorage = RecentSearchStorage(store: UserDefaultsStore())
    ) {
        self.userUuid = userUuid
        self.recentSearchStorage = recentSearchStorage
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return .just(.setRecentKeywords(recentSearchStorage.load()))

        case .searchTextChanged(let searchText):
            return search(searchText: searchText, shouldPersistKeyword: true)

        case .recentKeywordTapped(let keyword):
            return search(searchText: keyword, shouldPersistKeyword: false)

        case .recentKeywordRemoved(let keyword):
            recentSearchStorage.remove(keyword)
            return .just(.setRecentKeywords(recentSearchStorage.load()))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setRecentKeywords(let recentKeywords):
            newState.recentKeywords = recentKeywords
        case .setSearchText(let searchText):
            newState.searchText = searchText
            if searchText.isEmpty {
                newState.searchPopupList = []
                newState.errorMessage = nil
            }
        case .setSearchResults(let searchPopupList):
            newState.searchPopupList = searchPopupList
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }

    private func search(searchText: String, shouldPersistKeyword: Bool) -> AsyncStream<Reaction> {
        guard searchText.isEmpty == false else {
            return .concat(
                .just(.setSearchText(searchText)),
                .just(.setSearchResults([])),
                .just(.setLoading(false))
            )
        }

        return .concat(
            .just(.setSearchText(searchText)),
            .just(.setLoading(true)),
            .run { [userUuid, popupUsecase, recentSearchStorage] send in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                do {
                    let popups = try await popupUsecase.getPersonalSearchPopupList(
                        userUuid: userUuid,
                        searchText: searchText
                    )
                    await send(.setSearchResults(popups))
                    await send(.setErrorMessage(nil))

                    if shouldPersistKeyword {
                        try? await Task.sleep(for: .milliseconds(700))
                        guard !Task.isCancelled else { return }
                        recentSearchStorage.add(searchText)
                        await send(.setRecentKeywords(recentSearchStorage.load()))
                    }
                } catch {
                    await send(.setSearchResults([]))
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }
}
