import Domain
import Foundation

/// 소셜 SDK로 로그인하고 서버에 보낼 증명 값
public enum SocialCredential: Equatable, Sendable {
    case kakao(accessToken: String)
    case google(idToken: String)
    case apple(authCode: String, rawNonce: String)

    public var provider: Provider {
        switch self {
        case .kakao:
            return .kakao
        case .google:
            return .google
        case .apple:
            return .apple
        }
    }
}

/// 소셜 로그인 제공자마다 다른 SDK 로그인 단계
///
/// 서버 로그인은 `AuthRepositoryImpl`이 모든 제공자에 같은 방식으로 한다.
/// 새 제공자를 추가하려면 이 protocol을 채택한 전략 하나를 만든다.
public protocol SocialLoginStrategy: Sendable {
    var provider: Provider { get }

    /// 소셜 SDK로 로그인하고 서버에 보낼 증명 값을 돌려준다.
    /// - Throws: 사용자가 로그인 창을 닫으면 `AuthError.cancelled`
    func login() async throws -> SocialCredential
}

public enum SocialLoginError: Error, Equatable, Sendable {
    /// SDK가 성공했지만 증명 값이 없다.
    case credentialNotFound
    /// 로그인 화면을 띄울 화면이 없다.
    case presentingViewControllerNotFound
}
