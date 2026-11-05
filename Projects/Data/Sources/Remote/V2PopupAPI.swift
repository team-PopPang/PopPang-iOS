import Core
import Foundation
import Moya

/// V2 회원 팝업 API (명세 P3 묶음)
///
/// 모두 Access Token의 사용자를 기준으로 찜 여부·개인화를 계산하므로 경로에 `userUuid`를 넣지 않는다.
/// 팝업 목록 응답은 명세상 V1과 같은 감싸지 않은 팝업 배열(`wrapper NONE → NONE`)이라 `APIResponse` 없이 `PopupDTO`로 읽는다.
public enum V2PopupAPI {
    /// `GET /api/v2/user/popups/search` (UPOP-11). 검색어는 `q`로 보낸다.
    case search(q: String)
    /// `GET /api/v2/user/popups/{popupUuid}`. 상세 화면의 단건 조회다. 감싸지 않은 팝업 하나를 준다.
    case detail(popupUuid: String)
    /// `POST /api/v2/popup/{popupUuid}/view` (POP-14). 조회 기록을 남긴다. 응답 본문은 쓰지 않는다.
    case view(popupUuid: String)
    /// `GET /api/v2/user/popups/{popupUuid}/related` (UPOP-03). 상세 화면의 관련 팝업이다.
    case related(popupUuid: String)
    /// `GET /api/v2/user/popups/filtered/home` (UPOP-04). 지역·구·정렬로 거른 팝업 목록이다. 달력·홈이 쓴다.
    case filteredHome(region: String, district: String, homeSortStandard: String)
    /// `GET /api/v2/popup/regions/districts` (POP-10). 지역과 그 안의 구 목록이다.
    case regionList
}

extension V2PopupAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .search:
            return "/user/popups/search"
        case .detail(let popupUuid):
            return "/user/popups/\(popupUuid)"
        case .view(let popupUuid):
            return "/popup/\(popupUuid)/view"
        case .related(let popupUuid):
            return "/user/popups/\(popupUuid)/related"
        case .filteredHome:
            return "/user/popups/filtered/home"
        case .regionList:
            return "/popup/regions/districts"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .search, .detail, .related, .filteredHome, .regionList:
            return .get
        case .view:
            return .post
        }
    }

    public var task: Task {
        switch self {
        case .search(let q):
            return .requestParameters(parameters: ["q": q], encoding: URLEncoding.queryString)
        case let .filteredHome(region, district, homeSortStandard):
            return .requestParameters(
                parameters: [
                    "region": region,
                    "district": district,
                    "homeSortStandard": homeSortStandard,
                ],
                encoding: URLEncoding.queryString
            )
        case .detail, .view, .related, .regionList:
            return .requestPlain
        }
    }
}
