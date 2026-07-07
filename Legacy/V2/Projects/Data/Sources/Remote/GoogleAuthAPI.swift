import Core
import Foundation
import Moya

public enum GoogleAuthAPI {
    case login(idToken: String)
    case signup(userDTO: UserDTO)
}

extension GoogleAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .login:
            return "/auth/google/mobile/login"
        case .signup:
            return "/auth/google/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .login(let idToken):
            return .requestJSONEncodable(["id_token": idToken])
        case .signup(let userDTO):
            return .requestJSONEncodable(userDTO)
        }
    }
}
