import Core
import Domain
import Foundation
import KakaoSDKAuth
import KakaoSDKUser
import Moya

public final class KakaoAuthRepositoryImpl: KakaoAuthRepositoryProtocol {
    public init() {}

    public func kakaoLogin() async throws -> Domain.User {
        let oauthToken: OAuthToken

        if UserApi.isKakaoTalkLoginAvailable() {
            oauthToken = try await handleWithKakaoApp()
        } else {
            oauthToken = try await handleWithKakaoWeb()
        }

        return try await kakaoProvider.asyncRequest(
            .login(accessToken: oauthToken.accessToken),
            decodeTo: UserDTO.self
        ).toModel()
    }

    public func kakaoRegister(user: Domain.User) async throws -> Domain.User {
        try await kakaoProvider.asyncRequest(.signup(userDTO: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    @MainActor
    private func handleWithKakaoApp() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let oauthToken {
                    continuation.resume(returning: oauthToken)
                } else {
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
                }
            }
        }
    }

    @MainActor
    private func handleWithKakaoWeb() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let oauthToken {
                    continuation.resume(returning: oauthToken)
                } else {
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
                }
            }
        }
    }

    private var kakaoProvider: MoyaProvider<KakaoAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
