import Core
import Foundation
import Moya

public enum ServerHealthAPI {
    case getHealth
}

extension ServerHealthAPI: BaseAPI {
    /// `GET /api/v2/mobile/health`. 인증 없이 부른다(`authorization` 기본값 `.none`). 응답은 V1과 같은 `{ "isHealthy": Bool }`이다.
    public var apiVersion: APIVersion { .mobile }

    public var path: String {
        switch self {
        case .getHealth:
            return "/health"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getHealth:
            return .get
        }
    }

    public var task: Task {
        switch self {
        case .getHealth:
            return .requestPlain
        }
    }
}
