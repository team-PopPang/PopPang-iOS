import Core
import Foundation
import Moya

/// V2 알림 키워드 API
///
/// Access Token의 사용자로 처리하므로 경로·본문에 `userUuid`를 넣지 않는다.
public enum V2AlertKeywordAPI {
    /// `GET /api/v2/alert-keyword`. 성공 응답은 `APIResponse`로 감싼 `[{ alertKeyword }]`다.
    case list
    /// `POST /api/v2/alert-keyword`. 성공 응답은 본문이 없다. 이미 있는 키워드는 409 4004다.
    case add(keyword: String)
    /// `DELETE /api/v2/alert-keyword`. 서버가 DELETE에도 JSON 본문을 요구한다. 성공 응답은 본문이 없다. 없는 키워드는 404 4003이다.
    case remove(keyword: String)
}

extension V2AlertKeywordAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        "/alert-keyword"
    }

    public var method: Moya.Method {
        switch self {
        case .list:
            return .get
        case .add:
            return .post
        case .remove:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .list:
            return .requestPlain
        case .add(let keyword), .remove(let keyword):
            return .requestParameters(parameters: ["keyword": keyword], encoding: JSONEncoding.default)
        }
    }
}
