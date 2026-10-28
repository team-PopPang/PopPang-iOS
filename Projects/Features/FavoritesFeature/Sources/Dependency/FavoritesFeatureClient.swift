import ComposableArchitecture
import Domain

public struct FavoritesFeatureClient: Sendable {
    public var getFavoriteList: @Sendable () async throws -> [Popup]
    public var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getFavoriteList: @escaping @Sendable () async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getFavoriteList = getFavoriteList
        self.addFavorite = addFavorite
        self.removeFavorite = removeFavorite
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            getFavoriteList: {
                try await popupUsecaseBox.usecase.getFavoriteList()
            },
            addFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(popupUuid: popupUuid)
            },
            removeFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(popupUuid: popupUuid)
            }
        )
    }
}

extension FavoritesFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getFavoriteList: { [] },
        addFavorite: { _ in },
        removeFavorite: { _ in }
    )
}

extension FavoritesFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getFavoriteList: { [] },
        addFavorite: { _ in },
        removeFavorite: { _ in }
    )
}

extension DependencyValues {
    public var favoritesFeatureClient: FavoritesFeatureClient {
        get { self[FavoritesFeatureClient.self] }
        set { self[FavoritesFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
