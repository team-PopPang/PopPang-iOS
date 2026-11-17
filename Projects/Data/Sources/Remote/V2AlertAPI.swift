import Core
import Foundation
import Moya

/// V2 알림함 API
///
/// Access Token의 사용자로 처리하므로 경로·본문에 `userUuid`를 넣지 않는다.
public enum V2AlertAPI {
    /// `GET /api/v2/user/alert/popups`. 성공 응답은 `APIResponse`로 감싼 팝업 배열이다. 최근에 받은 알림부터 온다.
    case popups
    /// `DELETE /api/v2/user/alert`. 서버가 DELETE에도 JSON 본문을 요구한다. 성공 응답은 본문이 없다.
    case remove(popupUuid: String)
}

extension V2AlertAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .popups:
            return "/user/alert/popups"
        case .remove:
            return "/user/alert"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .popups:
            return .get
        case .remove:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .popups:
            return .requestPlain
        case .remove(let popupUuid):
            return .requestParameters(parameters: ["popupUuid": popupUuid], encoding: JSONEncoding.default)
        }
    }
}
