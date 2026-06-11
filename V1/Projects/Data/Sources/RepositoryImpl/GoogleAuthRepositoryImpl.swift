import Core
import Domain
import Foundation
import GoogleSignIn
import Moya
import UIKit

public final class GoogleAuthRepositoryImpl: GoogleAuthRepositoryProtocol {
    public init() {}

    @MainActor
    public func googleLogin() async throws -> Domain.User {
        let presentingVC = try await MainActor.run {
            guard
                let vc = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows
                    .first?
                    .rootViewController
            else {
                throw GoogleAuthError.noRootViewController
            }
            return vc
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
        let user = result.user
        let responseDTO = GoogleResponseDTO(
            oauthId: user.userID ?? "",
            idToken: user.idToken?.tokenString ?? ""
        )

        return try await googleProvider.asyncRequest(.login(idToken: responseDTO.idToken), decodeTo: UserDTO.self).toModel()
    }

    public func googleRegister(user: Domain.User) async throws -> Domain.User {
        try await googleProvider.asyncRequest(.signup(userDTO: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    private var googleProvider: MoyaProvider<GoogleAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
