import Domain
import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

/// 카카오톡 앱이 있으면 앱으로, 없으면 카카오 계정 웹 로그인으로 로그인한다.
public final class KakaoLoginStrategy: SocialLoginStrategy {
    public let provider: Provider = .kakao

    public init() {}

    public func login() async throws -> SocialCredential {
        do {
            let oauthToken = await MainActor.run { UserApi.isKakaoTalkLoginAvailable() }
                ? try await loginWithKakaoTalk()
                : try await loginWithKakaoAccount()
            return .kakao(accessToken: oauthToken.accessToken)
        } catch {
            throw Self.isCancelled(error) ? AuthError.cancelled : error
        }
    }
}

private extension KakaoLoginStrategy {
    @MainActor
    func loginWithKakaoTalk() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                Self.resume(continuation, oauthToken: oauthToken, error: error)
            }
        }
    }

    @MainActor
    func loginWithKakaoAccount() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                Self.resume(continuation, oauthToken: oauthToken, error: error)
            }
        }
    }

    static func resume(
        _ continuation: CheckedContinuation<OAuthToken, Error>,
        oauthToken: OAuthToken?,
        error: Error?
    ) {
        if let error {
            continuation.resume(throwing: error)
        } else if let oauthToken {
            continuation.resume(returning: oauthToken)
        } else {
            continuation.resume(throwing: SocialLoginError.credentialNotFound)
        }
    }

    /// 로그인 창을 닫거나(ClientFailed.Cancelled) 카카오톡 동의 화면에서 취소했는지(AuthFailed.AccessDenied) 확인한다.
    static func isCancelled(_ error: Error) -> Bool {
        switch error as? SdkError {
        case let .ClientFailed(reason, _):
            return reason == .Cancelled
        case let .AuthFailed(reason, _):
            return reason == .AccessDenied
        default:
            return false
        }
    }
}
