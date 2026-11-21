import ComposableArchitecture
import Domain

/// 지도 화면이 쓰는 서버 요청. 모두 V2라 Access Token의 사용자를 기준으로 하고 `userUuid`를 받지 않는다.
public struct MapFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    /// 지도 카테고리 전체와 마커 색. 필터의 카테고리 칩과 마커 색에 쓴다. 지도 탭에 처음 들어갈 때 한 번 받는다.
    public var getMapCategoryList: @Sendable () async throws -> [MapCategory]
    /// 지도 목록. 고른 조건을 서버에 보내고, 서버가 거른 결과를 받는다.
    public var searchMapPopups: @Sendable (_ query: MapPopupQuery) async throws -> MapPopupSearchResult
    public var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        getMapCategoryList: @escaping @Sendable () async throws -> [MapCategory],
        searchMapPopups: @escaping @Sendable (_ query: MapPopupQuery) async throws -> MapPopupSearchResult,
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.getMapCategoryList = getMapCategoryList
        self.searchMapPopups = searchMapPopups
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
            getMapCategoryList: {
                try await popupUsecaseBox.usecase.getMapCategoryList()
            },
            searchMapPopups: { query in
                // 지역·구·위치·정렬·카테고리·검색어를 서버에 보낸다. 앱에서 거르지 않는다.
                let items = try await popupUsecaseBox.usecase.getMapPopupList(
                    region: query.region,
                    district: query.district,
                    latitude: query.latitude,
                    longitude: query.longitude,
                    mapSortStandard: query.sort.rawValue,
                    recommendIds: query.filter.categoryIds.sorted(),
                    keyword: query.keyword
                )
                return MapPopupSearchResult(items: items, totalCount: items.count)
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

/// composition root에서 주입을 빠뜨리면 화면이 조용히 비지 않고 오류로 드러나게 한다.
struct MapFeatureUnimplementedError: Error {}

extension MapFeatureClient {
    public static let unimplemented = Self(
        getRegionList: { throw MapFeatureUnimplementedError() },
        getMapCategoryList: { throw MapFeatureUnimplementedError() },
        searchMapPopups: { _ in throw MapFeatureUnimplementedError() },
        addFavorite: { _ in throw MapFeatureUnimplementedError() },
        removeFavorite: { _ in throw MapFeatureUnimplementedError() }
    )
}

extension MapFeatureClient: DependencyKey {
    public static let liveValue = Self.unimplemented
}

extension MapFeatureClient: TestDependencyKey {
    public static let testValue = Self.unimplemented
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
