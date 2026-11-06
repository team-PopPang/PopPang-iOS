import ComposableArchitecture
import Domain

/// 지도 화면이 쓰는 서버 요청. 모두 V2라 Access Token의 사용자를 기준으로 하고 `userUuid`를 받지 않는다.
public struct MapFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    /// 추천 카테고리 전체. 필터의 카테고리 목록에 쓴다.
    public var getRecommendList: @Sendable () async throws -> [Recommend]
    /// 지도 목록. 고른 조건을 서버에 보내고, 서버가 거른 결과를 받는다.
    public var searchMapPopups: @Sendable (_ query: MapPopupQuery) async throws -> MapPopupSearchResult
    public var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        getRecommendList: @escaping @Sendable () async throws -> [Recommend],
        searchMapPopups: @escaping @Sendable (_ query: MapPopupQuery) async throws -> MapPopupSearchResult,
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.getRecommendList = getRecommendList
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
            getRecommendList: {
                try await popupUsecaseBox.usecase.getRecommendList()
            },
            searchMapPopups: { query in
                // 지금 지도 API(GET /api/v2/user/popups/filtered/map)는 지역·구·위치·정렬만 받는다.
                // 카테고리·상태·기간 조건은 API가 생기면 여기서 보낸다(MapAPISupport). 앱에서 거르지 않는다.
                let items = try await popupUsecaseBox.usecase.getMapPopupList(
                    region: query.region,
                    district: query.district,
                    latitude: query.latitude,
                    longitude: query.longitude,
                    mapSortStandard: query.sort.rawValue
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
        getRecommendList: { throw MapFeatureUnimplementedError() },
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
