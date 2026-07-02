import ComposableArchitecture
import Core
import Domain

public struct SearchFeatureClient: Sendable {
    public var loadRecentKeywords: @Sendable () -> [String]
    public var addRecentKeyword: @Sendable (String) -> Void
    public var removeRecentKeyword: @Sendable (String) -> Void
    public var searchPopups: @Sendable (_ userUuid: String, _ searchText: String) async throws -> [Popup]

    public init(
        loadRecentKeywords: @escaping @Sendable () -> [String],
        addRecentKeyword: @escaping @Sendable (String) -> Void,
        removeRecentKeyword: @escaping @Sendable (String) -> Void,
        searchPopups: @escaping @Sendable (_ userUuid: String, _ searchText: String) async throws -> [Popup]
    ) {
        self.loadRecentKeywords = loadRecentKeywords
        self.addRecentKeyword = addRecentKeyword
        self.removeRecentKeyword = removeRecentKeyword
        self.searchPopups = searchPopups
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol,
        recentSearchStorage: RecentSearchStorage
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            loadRecentKeywords: {
                recentSearchStorage.load()
            },
            addRecentKeyword: { keyword in
                recentSearchStorage.add(keyword)
            },
            removeRecentKeyword: { keyword in
                recentSearchStorage.remove(keyword)
            },
            searchPopups: { userUuid, searchText in
                try await popupUsecaseBox.usecase.getPersonalSearchPopupList(
                    userUuid: userUuid,
                    searchText: searchText
                )
            }
        )
    }
}

extension SearchFeatureClient: DependencyKey {
    public static let liveValue = Self(
        loadRecentKeywords: { [] },
        addRecentKeyword: { _ in },
        removeRecentKeyword: { _ in },
        searchPopups: { _, _ in [] }
    )
}

extension SearchFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        loadRecentKeywords: { [] },
        addRecentKeyword: { _ in },
        removeRecentKeyword: { _ in },
        searchPopups: { _, _ in [] }
    )
}

extension DependencyValues {
    public var searchFeatureClient: SearchFeatureClient {
        get { self[SearchFeatureClient.self] }
        set { self[SearchFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
