import ComposableArchitecture
import Domain

public struct FavoritesFeatureClient: Sendable {
    public var getFavoriteList: @Sendable (_ userUuid: String) async throws -> [Popup]
    public var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void

    public init(
        getFavoriteList: @escaping @Sendable (_ userUuid: String) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
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
            getFavoriteList: { userUuid in
                try await popupUsecaseBox.usecase.getFavoriteList(userUuid: userUuid)
            },
            addFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension FavoritesFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getFavoriteList: { _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
    )
}

extension FavoritesFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getFavoriteList: { _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
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
