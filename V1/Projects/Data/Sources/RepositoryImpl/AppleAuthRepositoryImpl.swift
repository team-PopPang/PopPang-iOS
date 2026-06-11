import AuthenticationServices
import Core
import Domain
import Foundation
import Moya

public final class AppleAuthRepositoryImpl: AppleAuthRepositoryProtocol {
    public init() {}

    public func appleLogin(authorization: ASAuthorization) async throws -> Domain.User {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let authCodeData = credential.authorizationCode,
            let authCode = String(data: authCodeData, encoding: .utf8)
        else {
            throw AppleAuthRepositoryError.authCodeNotFound
        }

        if let email = credential.email {
            return try await appleProvider.asyncRequest(
                .loginWithEmail(authCode: authCode, email: email),
                decodeTo: UserDTO.self
            ).toModel()
        } else {
            return try await appleProvider.asyncRequest(.login(authCode: authCode), decodeTo: UserDTO.self).toModel()
        }
    }

    public func appleRegister(user: Domain.User) async throws -> Domain.User {
        try await appleProvider.asyncRequest(.signup(userDto: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    private var appleProvider: MoyaProvider<AppleAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
