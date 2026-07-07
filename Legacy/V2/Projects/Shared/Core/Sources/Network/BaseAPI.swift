import Foundation
import Moya

public protocol BaseAPI: TargetType {}

public extension BaseAPI {
    var baseURL: URL {
        NetworkConfig.apiBaseURL
    }

    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json",
        ]
    }
}
