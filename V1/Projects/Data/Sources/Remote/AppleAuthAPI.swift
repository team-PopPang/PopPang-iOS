import Core
import Foundation
import Moya

public enum AppleAuthAPI {
    case loginWithEmail(authCode: String, email: String)
    case login(authCode: String)
    case signup(userDto: UserDTO)
}

extension AppleAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .loginWithEmail, .login:
            return "/auth/apple/mobile/login"
        case .signup:
            return "/auth/apple/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .loginWithEmail(let authCode, let email):
            return .requestJSONEncodable([
                "auth_code": authCode,
                "email": email,
            ])
        case .login(let authCode):
            return .requestJSONEncodable(["auth_code": authCode])
        case .signup(let userDto):
            return .requestJSONEncodable(userDto)
        }
    }
}
