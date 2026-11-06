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

/// 상태 필터. 지도 API가 아직 받지 않는다(서버는 운영 중 팝업만 준다).
public enum MapStatusFilter: String, CaseIterable, Equatable, Sendable {
    case all = "ALL"
    case inProgress = "IN_PROGRESS"
    case upcoming = "UPCOMING"
    case endingThisWeek = "ENDING_THIS_WEEK"

    var title: String {
        switch self {
        case .all:
            String(localized: "전체", bundle: .module)
        case .inProgress:
            String(localized: "진행 중", bundle: .module)
        case .upcoming:
            String(localized: "오픈 예정", bundle: .module)
        case .endingThisWeek:
            String(localized: "이번 주 종료", bundle: .module)
        }
    }
}

/// 기간 필터. 지도 API가 아직 받지 않는다.
public enum MapPeriodFilter: String, CaseIterable, Equatable, Sendable {
    case all = "ALL"
    case today = "TODAY"
    case thisWeek = "THIS_WEEK"
    case custom = "CUSTOM"

    var title: String {
        switch self {
        case .all:
            String(localized: "전체", bundle: .module)
        case .today:
            String(localized: "오늘", bundle: .module)
        case .thisWeek:
            String(localized: "이번 주", bundle: .module)
        case .custom:
            String(localized: "날짜 선택", bundle: .module)
        }
    }
}

/// 화면에서 고른 필터. 앱은 이 값으로 목록을 거르지 않고, 조회 조건으로 서버에 보낸다.
public struct MapPopupFilter: Equatable, Sendable {
    public var categoryIds: Set<Int> = []
    public var status: MapStatusFilter = .all
    public var period: MapPeriodFilter = .all

    public init(
        categoryIds: Set<Int> = [],
        status: MapStatusFilter = .all,
        period: MapPeriodFilter = .all
    ) {
        self.categoryIds = categoryIds
        self.status = status
        self.period = period
    }

    /// 기본값과 다른 조건 개수. 필터 아이콘 배지에 쓴다.
    var activeCount: Int {
        (categoryIds.isEmpty ? 0 : 1) + (status == .all ? 0 : 1) + (period == .all ? 0 : 1)
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
    static let category = false
    static let status = false
    static let period = false
    static let keyword = false
}
