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
                String(localized: "활동", bundle: .module)
            case .keyword:
                String(localized: "키워드 설정", bundle: .module)
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var nickname: String
        public var selectedTab: AlertTab = .activity
        public var alertPopups: [Popup] = []
        public var keywords: [Keyword] = []
        public var keywordText = ""
        public var recentKeywords: [String] = []
        public var isEditing = false
        public var isLoading = false
        public var errorMessage: String?
        /// 찜 요청이 끝나지 않은 팝업. 응답 전에 같은 팝업의 하트를 다시 누르면 무시한다.
        public var favoriteUpdatingPopupUuids: Set<String> = []

        public init(user: User) {
            self.nickname = user.nickname ?? String(localized: "닉네임", bundle: .module)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.nickname == rhs.nickname
                && lhs.selectedTab == rhs.selectedTab
                && lhs.alertPopups == rhs.alertPopups
                && lhs.keywords == rhs.keywords
                && lhs.keywordText == rhs.keywordText
                && lhs.recentKeywords == rhs.recentKeywords
                && lhs.isEditing == rhs.isEditing
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
                && lhs.favoriteUpdatingPopupUuids == rhs.favoriteUpdatingPopupUuids
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
                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.removeAlertPopup(popupUuid)
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
                state.errorMessage = Self.message(for: error, fallback: Self.deleteFailedMessage)
                return .none

            case .deleteAllPopupsTapped:
                let popupUuids = state.alertPopups.map(\.popupUuid)
                return .run { [alertFeatureClient] send in
                    do {
                        // V2에도 한꺼번에 지우는 API가 없어 하나씩 지운다.
                        for popupUuid in popupUuids {
                            try await alertFeatureClient.removeAlertPopup(popupUuid)
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
                state.errorMessage = Self.message(for: error, fallback: Self.deleteFailedMessage)
                return .none

            case .toggleLikeTapped(let popupUuid):
                guard !state.favoriteUpdatingPopupUuids.contains(popupUuid),
                      let currentPopup = state.alertPopups.first(where: { $0.popupUuid == popupUuid }) else {
                    return .none
                }
                state.favoriteUpdatingPopupUuids.insert(popupUuid)

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

                return .run { [alertFeatureClient] send in
                    do {
                        if currentPopup.isFavorited {
                            try await alertFeatureClient.removeFavorite(currentPopup.popupUuid)
                        } else {
                            try await alertFeatureClient.addFavorite(currentPopup.popupUuid)
                        }
                        await send(.toggleLikeResponse(.success(()), currentPopup))
                    } catch {
                        await send(.toggleLikeResponse(.failure(error), currentPopup))
                    }
                }

            case .toggleLikeResponse(.success, let originalPopup):
                state.favoriteUpdatingPopupUuids.remove(originalPopup.popupUuid)
                state.errorMessage = nil
                return .none

            case .toggleLikeResponse(.failure(let error), let originalPopup):
                state.favoriteUpdatingPopupUuids.remove(originalPopup.popupUuid)
                replacePopup(in: &state.alertPopups, popup: originalPopup)
                state.errorMessage = Self.message(for: error, fallback: Self.favoriteFailedMessage)
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

                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.addAlertKeyword(keyword.keyword)
                        await send(.addKeywordResponse(.success(()), keyword))
                    } catch {
                        await send(.addKeywordResponse(.failure(error), keyword))
                    }
                }

            case .addKeywordResponse(.success, _):
                return .none

            case .addKeywordResponse(.failure(let error), _) where error as? AlertKeywordError == .alreadyExists:
                // 서버에 이미 있는 키워드다. 등록하려던 상태와 같으므로 목록에 남긴다.
                return .none

            case .addKeywordResponse(.failure(let error), let keyword):
                state.keywords.removeAll { $0 == keyword }
                state.errorMessage = Self.message(for: error, fallback: Self.addKeywordFailedMessage)
                return .none

            case .removeKeywordTapped(let keyword):
                state.keywords.removeAll { $0 == keyword }

                return .run { [alertFeatureClient] send in
                    do {
                        try await alertFeatureClient.removeAlertKeyword(keyword.keyword)
                        await send(.removeKeywordResponse(.success(()), keyword))
                    } catch {
                        await send(.removeKeywordResponse(.failure(error), keyword))
                    }
                }

            case .removeKeywordResponse(.success, _):
                state.errorMessage = nil
                return .none

            case .removeKeywordResponse(.failure(let error), let keyword):
                if !state.keywords.contains(keyword) {
                    state.keywords.append(keyword)
                }
                state.errorMessage = Self.message(for: error, fallback: Self.removeKeywordFailedMessage)
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
        .run { [alertFeatureClient] send in
            do {
                async let alertPopups = alertFeatureClient.getAlertPopupList()
                async let keywords = alertFeatureClient.getAlertKeywordList()
                let recentKeywords = alertFeatureClient.loadRecentKeywords()

                await send(.initialDataLoaded(
                    try await alertPopups,
                    try await keywords,
                    recentKeywords
                ))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
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

    /// 실패를 화면 문구로 바꾼다. 다시 로그인해야 하는 실패는 앱이 로그인 화면으로 보내므로 문구를 띄우지 않는다.
    static func message(for error: Error, fallback: String) -> String? {
        error is AuthSessionError ? nil : fallback
    }

    static var loadFailedMessage: String {
        String(localized: "알림을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var deleteFailedMessage: String {
        String(localized: "알림을 지우지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var favoriteFailedMessage: String {
        String(localized: "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var addKeywordFailedMessage: String {
        String(localized: "키워드를 등록하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var removeKeywordFailedMessage: String {
        String(localized: "키워드를 지우지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }
}
