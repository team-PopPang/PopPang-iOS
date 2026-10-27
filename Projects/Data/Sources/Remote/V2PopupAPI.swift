import Core
import Foundation
import Moya

/// V2 회원 팝업 API (명세 P3 묶음)
///
/// 모두 Access Token의 사용자를 기준으로 찜 여부·개인화를 계산하므로 경로에 `userUuid`를 넣지 않는다.
/// 성공 응답은 V1과 같은 감싸지 않은 팝업 배열이라 `PopupDTO`로 읽는다.
public enum V2PopupAPI {
    /// `GET /api/v2/user/popups/search` (UPOP-11). 검색어는 `q`로 보낸다.
    case search(q: String)
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
        }
    }

    public var method: Moya.Method {
        switch self {
        case .search:
            return .get
        }
    }

    public var task: Task {
        switch self {
        case .search(let q):
            return .requestParameters(parameters: ["q": q], encoding: URLEncoding.queryString)
        }
    }
}
