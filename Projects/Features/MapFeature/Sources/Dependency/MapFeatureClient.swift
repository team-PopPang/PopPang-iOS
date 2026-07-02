import ComposableArchitecture
import Domain

public struct MapFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    public var getPopularRecommendList: @Sendable () async throws -> [Recommend]
    public var getPopularRecommendPopupList: @Sendable (
        _ userUuid: String,
        _ recommendId: Int
    ) async throws -> [Popup]
    public var getPersonalMapFilteredPopupList: @Sendable (
        _ userUuid: String,
        _ region: String,
        _ district: String,
        _ latitude: Double?,
        _ longitude: Double?,
        _ mapSortStandard: String
    ) async throws -> [Popup]
    public var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        getPopularRecommendList: @escaping @Sendable () async throws -> [Recommend],
        getPopularRecommendPopupList: @escaping @Sendable (
            _ userUuid: String,
            _ recommendId: Int
        ) async throws -> [Popup],
        getPersonalMapFilteredPopupList: @escaping @Sendable (
            _ userUuid: String,
            _ region: String,
            _ district: String,
            _ latitude: Double?,
            _ longitude: Double?,
            _ mapSortStandard: String
        ) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.getPopularRecommendList = getPopularRecommendList
        self.getPopularRecommendPopupList = getPopularRecommendPopupList
        self.getPersonalMapFilteredPopupList = getPersonalMapFilteredPopupList
        self.addFavorite = addFavorite
        self.removeFavorite = removeFavorite
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            getRegionList: {
                try await popupUsecaseBox.usecase.getRegionList()
            },
            getPopularRecommendList: {
                try await popupUsecaseBox.usecase.getPopularRecommendList()
            },
            getPopularRecommendPopupList: { userUuid, recommendId in
                try await popupUsecaseBox.usecase.getPopularRecommendPopupList(
                    userUuid: userUuid,
                    recommendId: recommendId
                )
            },
            getPersonalMapFilteredPopupList: { userUuid, region, district, latitude, longitude, mapSortStandard in
                try await popupUsecaseBox.usecase.getPersonalMapFilteredPopupList(
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    latitude: latitude,
                    longitude: longitude,
                    mapSortStandard: mapSortStandard
                )
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

extension MapFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getRegionList: { [] },
        getPopularRecommendList: { [] },
        getPopularRecommendPopupList: { _, _ in [] },
        getPersonalMapFilteredPopupList: { _, _, _, _, _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
    )
}

extension MapFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getRegionList: { [] },
        getPopularRecommendList: { [] },
        getPopularRecommendPopupList: { _, _ in [] },
        getPersonalMapFilteredPopupList: { _, _, _, _, _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
    )
}

extension DependencyValues {
    public var mapFeatureClient: MapFeatureClient {
        get { self[MapFeatureClient.self] }
        set { self[MapFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
