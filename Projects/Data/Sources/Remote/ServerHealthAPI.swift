import Core
import Foundation
import Moya

public enum ServerHealthAPI {
    case getHealth
}

extension ServerHealthAPI: BaseAPI {
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
