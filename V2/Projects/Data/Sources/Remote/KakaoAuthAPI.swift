import Core
import Foundation
import Moya

public enum KakaoAuthAPI {
    case login(accessToken: String)
    case signup(userDTO: UserDTO)
}

extension KakaoAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .login:
            return "/auth/kakao/mobile/login"
        case .signup:
            return "/auth/kakao/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .login(let accessToken):
            return .requestJSONEncodable(["access_token": accessToken])
        case .signup(let userDTO):
            return .requestJSONEncodable(userDTO)
        }
    }
}
