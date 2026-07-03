import ComposableArchitecture
import Core
import Domain
import Foundation

@Reducer
public struct AlertFeature {
    public enum AlertTab: Int, CaseIterable, Equatable, Sendable {
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

    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
        public var selectedTab: AlertTab = .activity
        public var alertPopups: [Popup] = []
        public var keywords: [Keyword] = []
        public var keywordText = ""
        public var recentKeywords: [String] = []
        public var isEditing = false
        public var isLoading = false
        public var errorMessage: String?

        public init(session: Shared<UserSession>) {
            self._session = session
        }

        var currentUser: User {
            guard let user = session.user else {
                preconditionFailure("AlertFeature requires a logged in session.")
            }
            return user
        }

        public var userUuid: String {
            currentUser.userUuid
        }

        public var nickname: String {
            currentUser.nickname ?? "닉네임"
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.nickname == rhs.nickname
                && lhs.selectedTab == rhs.selectedTab
                && lhs.alertPopups == rhs.alertPopups
                && lhs.keywords == rhs.keywords
                && lhs.keywordText == rhs.keywordText
                && lhs.recentKeywords == rhs.recentKeywords
                && lhs.isEditing == rhs.isEditing
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case onAppear
        case tabChanged(AlertTab)
        case toggleEditing
        case popupSelected(Popup)
        case deletePopupTapped(String)
        case deletePopupResponse(Result<String, Error>)
        case deleteAllPopupsTapped
        case deleteAllPopupsResponse(Result<Void, Error>)
        case toggleLikeTapped(String)
        case toggleLikeResponse(Result<Void, Error>, Popup)
        case keywordTextChanged(String)
        case addKeywordTapped(String)
        case addKeywordResponse(Result<Void, Error>, Keyword)
        case removeKeywordTapped(Keyword)
        case removeKeywordResponse(Result<Void, Error>, Keyword)
        case recentKeywordTapped(String)
        case recentKeywordRemoved(String)
        case initialDataLoaded([Popup], [Keyword], [String])
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case popupSelected(Popup)
        }
    }

    @Dependency(\.alertFeatureClient) private var alertFeatureClient: AlertFeatureClient
    private let maxKeywordCount = 5

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadInitialData(state: state)

            case .tabChanged(let tab):
                state.selectedTab = tab
                return .none

            case .toggleEditing:
                state.isEditing.toggle()
                return .none

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .deletePopupTapped(let popupUuid):
                let userUuid = state.userUuid
                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.removeAlertPopup(userUuid, popupUuid)
                        await send(.deletePopupResponse(.success(popupUuid)))
                    } catch {
                        await send(.deletePopupResponse(.failure(error)))
                    }
                }

            case .deletePopupResponse(.success(let popupUuid)):
                state.alertPopups.removeAll { $0.popupUuid == popupUuid }
                state.errorMessage = nil
                return .none

            case .deletePopupResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .deleteAllPopupsTapped:
                let userUuid = state.userUuid
                let popupUuids = state.alertPopups.map(\.popupUuid)
                return .run { [alertFeatureClient] send in
                    do {
                        for popupUuid in popupUuids {
                            try await alertFeatureClient.removeAlertPopup(userUuid, popupUuid)
                        }
                        await send(.deleteAllPopupsResponse(.success(())))
                    } catch {
                        await send(.deleteAllPopupsResponse(.failure(error)))
                    }
                }

            case .deleteAllPopupsResponse(.success):
                state.alertPopups.removeAll()
                state.errorMessage = nil
                return .none

            case .deleteAllPopupsResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .toggleLikeTapped(let popupUuid):
                guard let currentPopup = state.alertPopups.first(where: { $0.popupUuid == popupUuid }) else {
                    return .none
                }

                let nextIsFavorited = !currentPopup.isFavorited
                let nextFavoriteCount = nextIsFavorited
                    ? currentPopup.favoriteCount + 1
                    : max(0, currentPopup.favoriteCount - 1)
                updateFavorite(
                    in: &state.alertPopups,
                    popupUuid: popupUuid,
                    isFavorited: nextIsFavorited,
                    favoriteCount: nextFavoriteCount
                )

                let userUuid = state.userUuid
                return .run { [alertFeatureClient] send in
                    do {
                        if currentPopup.isFavorited {
                            try await alertFeatureClient.removeFavorite(userUuid, currentPopup.popupUuid)
                        } else {
                            try await alertFeatureClient.addFavorite(userUuid, currentPopup.popupUuid)
                        }
                        await send(.toggleLikeResponse(.success(()), currentPopup))
                    } catch {
                        await send(.toggleLikeResponse(.failure(error), currentPopup))
                    }
                }

            case .toggleLikeResponse(.success, _):
                state.errorMessage = nil
                return .none

            case .toggleLikeResponse(.failure(let error), let originalPopup):
                replacePopup(in: &state.alertPopups, popup: originalPopup)
                state.errorMessage = error.localizedDescription
                return .none

            case .keywordTextChanged(let text):
                state.keywordText = text
                return .none

            case .addKeywordTapped(let text):
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                guard state.keywords.count < maxKeywordCount else { return .none }

                let keyword = Keyword(keyword: trimmed)
                guard !state.keywords.contains(keyword) else {
                    state.keywordText = ""
                    state.errorMessage = nil
                    return .none
                }

                state.keywords.append(keyword)
                state.keywordText = ""
                state.errorMessage = nil

                let userUuid = state.userUuid
                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.addAlertKeyword(userUuid, keyword.keyword)
                        await send(.addKeywordResponse(.success(()), keyword))
                    } catch {
                        await send(.addKeywordResponse(.failure(error), keyword))
                    }
                }

            case .addKeywordResponse(.success, _):
                return .none

            case .addKeywordResponse(.failure(let error), let keyword):
                state.keywords.removeAll { $0 == keyword }
                state.errorMessage = error.localizedDescription
                return .none

            case .removeKeywordTapped(let keyword):
                state.keywords.removeAll { $0 == keyword }

                let userUuid = state.userUuid
                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.removeAlertKeyword(userUuid, keyword.keyword)
                        await send(.removeKeywordResponse(.success(()), keyword))
                    } catch {
                        await send(.removeKeywordResponse(.failure(error), keyword))
                    }
                }

            case .removeKeywordResponse(.success, _):
                state.errorMessage = nil
                return .none

            case .removeKeywordResponse(.failure(let error), let keyword):
                guard !state.keywords.contains(keyword) else {
                    state.errorMessage = error.localizedDescription
                    return .none
                }
                state.keywords.append(keyword)
                state.errorMessage = error.localizedDescription
                return .none

            case .recentKeywordTapped(let keyword):
                return .send(.addKeywordTapped(keyword))

            case .recentKeywordRemoved(let keyword):
                alertFeatureClient.removeRecentKeyword(keyword)
                state.recentKeywords = alertFeatureClient.loadRecentKeywords()
                return .none

            case .initialDataLoaded(let alertPopups, let keywords, let recentKeywords):
                state.alertPopups = alertPopups
                state.keywords = keywords
                state.recentKeywords = recentKeywords
                state.errorMessage = nil
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension AlertFeature {
    func loadInitialData(state: State) -> Effect<Action> {
        let userUuid = state.userUuid

        return .run { [alertFeatureClient] send in
            do {
                async let alertPopups = alertFeatureClient.getAlertPopupList(userUuid)
                async let keywords = alertFeatureClient.getAlertKeywordList(userUuid)
                let recentKeywords = alertFeatureClient.loadRecentKeywords()

                await send(.initialDataLoaded(
                    try await alertPopups,
                    try await keywords,
                    recentKeywords
                ))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func updateFavorite(
        in popups: inout [Popup],
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        guard let index = popups.firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        popups[index].isFavorited = isFavorited
        popups[index].favoriteCount = favoriteCount
    }

    func replacePopup(in popups: inout [Popup], popup: Popup) {
        guard let index = popups.firstIndex(where: { $0.popupUuid == popup.popupUuid }) else { return }
        popups[index] = popup
    }
}
