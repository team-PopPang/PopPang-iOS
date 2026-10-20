import Core
import Foundation
import Moya

/// V2 토큰 갱신 API
///
/// 인증 plugin이 없는 provider로 부른다. 갱신 요청에 다시 갱신을 걸지 않기 위해서다.
public enum AuthTokenRefreshAPI {
    case refresh(refreshToken: String)
}

extension AuthTokenRefreshAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var path: String {
        "/auth/refresh"
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .refresh(let refreshToken):
            return .requestJSONEncodable(["refreshToken": refreshToken])
        }
    }
}

public enum AuthTokenRefresh {
    /// `AccessTokenRefresher`에 넣을 갱신 함수를 만든다.
    public static func live(
        networkProvider: NetworkProvider = NetworkProvider()
    ) -> AccessTokenRefresher.Refresh {
        let provider: MoyaProvider<AuthTokenRefreshAPI> = networkProvider.makeProvider()
        return { refreshToken in
            let tokens = try await provider.asyncRequest(
                .refresh(refreshToken: refreshToken),
                decodeDataTo: V2TokenDTO.self
            )
            return AuthTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        }
    }
}
