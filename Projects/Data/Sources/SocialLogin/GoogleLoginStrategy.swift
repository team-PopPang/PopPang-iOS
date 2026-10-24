import Domain
import Foundation
import GoogleSignIn
import UIKit

/// Google 계정으로 로그인하고 ID Token을 받는다.
public final class GoogleLoginStrategy: SocialLoginStrategy {
    public let provider: Provider = .google

    public init() {}

    public func login() async throws -> SocialCredential {
        do {
            return try await signIn()
        } catch {
            throw (error as? GIDSignInError)?.code == .canceled ? AuthError.cancelled : error
        }
    }
}

private extension GoogleLoginStrategy {
    @MainActor
    func signIn() async throws -> SocialCredential {
        guard let presentingViewController = UIApplication.shared.topViewController else {
            throw SocialLoginError.presentingViewControllerNotFound
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SocialLoginError.credentialNotFound
        }
        return .google(idToken: idToken)
    }
}
