import Domain
import Foundation

/// 지도 목록 정렬. 서버 `mapSortStandard` 값과 같다.
public enum MapSortOption: String, CaseIterable, Equatable, Sendable {
    case closest = "CLOSEST"
    case newest = "NEWEST"
    case closingSoon = "CLOSING_SOON"
    case mostFavorited = "MOST_FAVORITED"
    case mostViewed = "MOST_VIEWED"

    var title: String {
        switch self {
        case .closest:
            String(localized: "가까운순", bundle: .module)
        case .newest:
            String(localized: "최신순", bundle: .module)
        case .closingSoon:
            String(localized: "마감순", bundle: .module)
        case .mostFavorited:
            String(localized: "좋아요순", bundle: .module)
        case .mostViewed:
            String(localized: "조회순", bundle: .module)
        }
    }
}

/// 화면에서 고른 필터. 앱은 이 값으로 목록을 거르지 않고, 조회 조건으로 서버에 보낸다.
/// 피그마 결정(2026-11-17)으로 상태·기간은 빼고 카테고리만 둔다.
public struct MapPopupFilter: Equatable, Sendable {
    /// 고른 카테고리. 서버의 `recommendIds`로 보내고, 하나라도 해당하는 팝업을 받는다.
    public var categoryIds: Set<Int> = []

    public init(categoryIds: Set<Int> = []) {
        self.categoryIds = categoryIds
    }

    /// 기본값과 다른 조건 개수. 필터 아이콘 배지에 쓴다.
    var activeCount: Int {
        categoryIds.isEmpty ? 0 : 1
    }
}

/// 지도 목록 조회 조건. 서버가 거르고 정렬한다.
public struct MapPopupQuery: Equatable, Sendable {
    public var region: String
    public var district: String
    public var latitude: Double?
    public var longitude: Double?
    public var sort: MapSortOption
    public var filter: MapPopupFilter

    public init(
        region: String = "전체",
        district: String = "전체",
        latitude: Double? = nil,
        longitude: Double? = nil,
        sort: MapSortOption = .closest,
        filter: MapPopupFilter = MapPopupFilter()
    ) {
        self.region = region
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.sort = sort
        self.filter = filter
    }
}

/// 지도 목록 조회 결과.
public struct MapPopupSearchResult: Equatable, Sendable {
    public var items: [Popup]
    /// 결과 개수. 서버가 개수를 주면 그 값을 쓴다. 지금 지도 API는 개수를 주지 않아 받은 목록의 개수다.
    public var totalCount: Int

    public init(items: [Popup], totalCount: Int) {
        self.items = items
        self.totalCount = totalCount
    }
}

/// 지도 API가 아직 지원하지 않는 기능. 화면에 "(x)"를 붙여 표시하고, 조건은 서버에 보내지 않는다.
/// API가 생기면 해당 값을 `true`로 바꾸고 `MapFeatureClient.live`에서 조건을 보낸다.
enum MapAPISupport {
    static let keyword = false
}

/// 마커 색을 고르는 규칙. 팝업 응답의 `recommendList`(카테고리 이름)를 지도 카테고리(`recommend/map`) 이름과 맞춘다.
enum MapMarkerColor {
    /// 팝업 마커에 쓸 색(`#RRGGBB`). 맞는 카테고리가 없으면 `nil`이고, 마커는 회색으로 그린다.
    ///
    /// - 카테고리 필터를 걸었으면 팝업의 카테고리 중 고른 카테고리를 먼저 본다. 고른 것과 다른 색이 보이지 않게 하려는 것이다.
    /// - 그 밖에는 팝업의 `recommendList` 순서대로 색이 있는 첫 카테고리의 색이다.
    static func colorHex(for popup: Popup, categories: [MapCategory], selectedIds: Set<Int>) -> String? {
        colorHex(for: popup, byName: index(categories), selectedIds: selectedIds)
    }

    /// 팝업별 마커 색. 카테고리 이름표를 한 번만 만들어 모든 팝업에 쓴다. 맞는 카테고리가 없는 팝업은 넣지 않는다.
    static func colorHexes(for popups: [Popup], categories: [MapCategory], selectedIds: Set<Int>) -> [String: String] {
        let byName = index(categories)
        var colors: [String: String] = [:]
        for popup in popups {
            colors[popup.popupUuid] = colorHex(for: popup, byName: byName, selectedIds: selectedIds)
        }
        return colors
    }

    /// 카테고리 이름(앞뒤 공백 제거) → 카테고리. 이름이 겹치면 앞의 것을 쓴다.
    private static func index(_ categories: [MapCategory]) -> [String: MapCategory] {
        var byName: [String: MapCategory] = [:]
        for category in categories {
            let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if byName[name] == nil { byName[name] = category }
        }
        return byName
    }

    private static func colorHex(for popup: Popup, byName: [String: MapCategory], selectedIds: Set<Int>) -> String? {
        let matched = popup.recommendList.compactMap {
            byName[$0.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        if selectedIds.isEmpty == false, let selected = matched.first(where: { selectedIds.contains($0.id) }) {
            return selected.colorHex
        }
        return matched.first?.colorHex
    }
}
