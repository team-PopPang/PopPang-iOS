import Compound
import Core
import Domain
import Foundation

@Compound
final class AlertFeatureCompound {
    enum AlertTab: Int, CaseIterable {
        case activity
        case keyword

        var title: String {
            switch self {
            case .activity:
                "활동"
            case .keyword:
                "키워드 설정"
            }
        }
    }

    enum Action {
        case onAppear
        case refresh
        case tabChanged(AlertTab)
        case toggleEditing
        case deletePopup(String)
        case deleteAllPopups
        case toggleLike(String)
        case keywordTextChanged(String)
        case addKeyword(String)
        case removeKeyword(Keyword)
        case addRecentKeyword(String)
        case removeRecentKeyword(String)
        case clearMessage
    }

    enum Reaction {
        case setLoading(Bool)
        case setSelectedTab(AlertTab)
        case setEditing(Bool)
        case setAlertPopups([Popup])
        case removeAlertPopup(String)
        case clearAlertPopups
        case updateFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case setKeywords([Keyword])
        case appendKeyword(Keyword)
        case removeKeyword(String)
        case setKeywordText(String)
        case setRecentKeywords([String])
        case setMessage(String?)
    }

    struct State: Equatable {
        var userUuid: String
        var nickname: String
        var selectedTab: AlertTab = .activity
        var alertPopups: [Popup] = []
        var keywords: [Keyword] = []
        var keywordText = ""
        var recentKeywords: [String] = []
        var isEditing = false
        var isLoading = false
        var message: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Dependency private var userUsecase: UserUsecaseProtocol

    private let recentSearchStorage: RecentSearchStorage
    private let maxKeywordCount = 5

    init(
        userUuid: String,
        nickname: String,
        recentSearchStorage: RecentSearchStorage = RecentSearchStorage(store: UserDefaultsStore())
    ) {
        self.state = State(userUuid: userUuid, nickname: nickname)
        self.recentSearchStorage = recentSearchStorage
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear, .refresh:
            return loadInitialData()

        case .tabChanged(let tab):
            return .just(.setSelectedTab(tab))

        case .toggleEditing:
            return .just(.setEditing(!state.isEditing))

        case .deletePopup(let popupUuid):
            return deletePopup(popupUuid: popupUuid)

        case .deleteAllPopups:
            return deleteAllPopups()

        case .toggleLike(let popupUuid):
            return toggleLike(popupUuid: popupUuid)

        case .keywordTextChanged(let text):
            return .just(.setKeywordText(text))

        case .addKeyword(let text):
            return addKeyword(text)

        case .removeKeyword(let keyword):
            return removeKeyword(keyword)

        case .addRecentKeyword(let keyword):
            return addKeyword(keyword)

        case .removeRecentKeyword(let keyword):
            recentSearchStorage.remove(keyword)
            return .just(.setRecentKeywords(recentSearchStorage.load()))

        case .clearMessage:
            return .just(.setMessage(nil))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setSelectedTab(let tab):
            newState.selectedTab = tab
        case .setEditing(let isEditing):
            newState.isEditing = isEditing
        case .setAlertPopups(let popups):
            newState.alertPopups = popups
        case .removeAlertPopup(let popupUuid):
            newState.alertPopups.removeAll { $0.popupUuid == popupUuid }
        case .clearAlertPopups:
            newState.alertPopups.removeAll()
        case let .updateFavorite(popupUuid, isFavorited, favoriteCount):
            guard let index = newState.alertPopups.firstIndex(where: { $0.popupUuid == popupUuid }) else { break }
            newState.alertPopups[index].isFavorited = isFavorited
            newState.alertPopups[index].favoriteCount = favoriteCount
        case .setKeywords(let keywords):
            newState.keywords = keywords
        case .appendKeyword(let keyword):
            guard !newState.keywords.contains(keyword) else { break }
            newState.keywords.append(keyword)
        case .removeKeyword(let keyword):
            newState.keywords.removeAll { $0.keyword == keyword }
        case .setKeywordText(let text):
            newState.keywordText = text
        case .setRecentKeywords(let keywords):
            newState.recentKeywords = keywords
        case .setMessage(let message):
            newState.message = message
        }

        return newState
    }
}

private extension AlertFeatureCompound {
    func loadInitialData() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase
        let userUsecase = userUsecase
        let recentSearchStorage = recentSearchStorage

        return .concat(
            .just(.setLoading(true)),
            .just(.setMessage(nil)),
            .run { [state, popupUsecase, userUsecase, recentSearchStorage] send in
                do {
                    async let alertPopups = popupUsecase.getAlertPopupList(userUuid: state.userUuid)
                    async let keywords = userUsecase.getAlertKeywordList(userUuid: state.userUuid)

                    await send(.setAlertPopups(try await alertPopups))
                    await send(.setKeywords(try await keywords))
                    await send(.setRecentKeywords(recentSearchStorage.load()))
                } catch {
                    await send(.setMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func deletePopup(popupUuid: String) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .run { [state, popupUsecase] send in
            do {
                try await popupUsecase.removeAlertPopup(
                    userUuid: state.userUuid,
                    popupUuid: popupUuid
                )
                await send(.removeAlertPopup(popupUuid))
                await send(.setMessage(nil))
            } catch {
                await send(.setMessage(error.localizedDescription))
            }
        }
    }

    func deleteAllPopups() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase
        let popups = state.alertPopups

        return .run { [state, popupUsecase, popups] send in
            do {
                for popup in popups {
                    try await popupUsecase.removeAlertPopup(
                        userUuid: state.userUuid,
                        popupUuid: popup.popupUuid
                    )
                }
                await send(.clearAlertPopups)
                await send(.setMessage(nil))
            } catch {
                await send(.setMessage(error.localizedDescription))
            }
        }
    }

    func toggleLike(popupUuid: String) -> AsyncStream<Reaction> {
        guard let currentPopup = state.alertPopups.first(where: { $0.popupUuid == popupUuid }) else {
            return Self.emptyReactionStream()
        }

        let popupUsecase = popupUsecase
        let nextIsFavorited = !currentPopup.isFavorited
        let nextFavoriteCount = nextIsFavorited
            ? currentPopup.favoriteCount + 1
            : max(0, currentPopup.favoriteCount - 1)

        return .concat(
            .just(.updateFavorite(
                popupUuid: popupUuid,
                isFavorited: nextIsFavorited,
                favoriteCount: nextFavoriteCount
            )),
            .run { [state, popupUsecase, currentPopup] send in
                do {
                    if currentPopup.isFavorited {
                        try await popupUsecase.removeFavorite(
                            userUuid: state.userUuid,
                            popupUuid: currentPopup.popupUuid
                        )
                    } else {
                        try await popupUsecase.addFavorite(
                            userUuid: state.userUuid,
                            popupUuid: currentPopup.popupUuid
                        )
                    }
                    await send(.setMessage(nil))
                } catch {
                    await send(.updateFavorite(
                        popupUuid: currentPopup.popupUuid,
                        isFavorited: currentPopup.isFavorited,
                        favoriteCount: currentPopup.favoriteCount
                    ))
                    await send(.setMessage(error.localizedDescription))
                }
            }
        )
    }

    func addKeyword(_ text: String) -> AsyncStream<Reaction> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Self.emptyReactionStream() }

        if state.keywords.count >= maxKeywordCount {
            return .just(.setMessage("키워드는 최대 5개까지 등록할 수 있습니다."))
        }

        let keyword = Keyword(keyword: trimmed)
        guard !state.keywords.contains(keyword) else {
            return .concat(
                .just(.setKeywordText("")),
                .just(.setMessage(nil))
            )
        }

        let userUsecase = userUsecase

        return .concat(
            .just(.appendKeyword(keyword)),
            .just(.setKeywordText("")),
            .just(.setMessage(nil)),
            .run { [state, userUsecase, keyword] send in
                do {
                    try await userUsecase.addAlertKeyword(
                        userUuid: state.userUuid,
                        alertKeyword: keyword.keyword
                    )
                } catch {
                    await send(.removeKeyword(keyword.keyword))
                    await send(.setMessage(error.localizedDescription))
                }
            }
        )
    }

    func removeKeyword(_ keyword: Keyword) -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.removeKeyword(keyword.keyword)),
            .run { [state, userUsecase, keyword] send in
                do {
                    try await userUsecase.removeAlertKeyword(
                        userUuid: state.userUuid,
                        alertKeyword: keyword.keyword
                    )
                    await send(.setMessage(nil))
                } catch {
                    await send(.appendKeyword(keyword))
                    await send(.setMessage(error.localizedDescription))
                }
            }
        )
    }

    static func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
