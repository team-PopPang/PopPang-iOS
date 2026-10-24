import AuthenticationServices
import CryptoKit
import Domain
import Foundation
import Security
import UIKit

/// Sign in with Apple로 로그인하고 authorization code와 nonce 원문을 받는다.
///
/// 요청마다 새 nonce 원문을 만들고, Apple 요청에는 그 SHA-256 값(소문자 16진수)을 넣는다.
/// 서버는 ID Token의 nonce가 `SHA-256(raw_nonce)`와 같은지 확인한다.
public final class AppleLoginStrategy: SocialLoginStrategy {
    public let provider: Provider = .apple

    public init() {}

    public func login() async throws -> SocialCredential {
        let rawNonce = try Self.makeRawNonce()
        let authorization: ASAuthorization
        do {
            authorization = try await AppleAuthorizationSession.authorize(hashedNonce: Self.sha256(rawNonce))
        } catch let error as ASAuthorizationError where error.code == .canceled {
            throw AuthError.cancelled
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8)
        else {
            throw SocialLoginError.credentialNotFound
        }
        return .apple(authCode: authCode, rawNonce: rawNonce)
    }
}

extension AppleLoginStrategy {
    /// 32바이트 난수를 16진수 문자열로 만든다.
    static func makeRawNonce() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw SocialLoginError.credentialNotFound
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// UTF-8 문자열의 SHA-256 값을 소문자 16진수로 만든다.
    static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

/// `ASAuthorizationController`의 delegate 결과를 async로 바꾼다. 요청이 끝날 때까지 자신과 controller를 붙잡아 둔다.
@MainActor
private final class AppleAuthorizationSession: NSObject {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private var controller: ASAuthorizationController?

    static func authorize(hashedNonce: String) async throws -> ASAuthorization {
        try await AppleAuthorizationSession().start(hashedNonce: hashedNonce)
    }

    private func start(hashedNonce: String) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<ASAuthorization, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
    }
}

extension AppleAuthorizationSession: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(.success(authorization))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(.failure(error))
    }
}

extension AppleAuthorizationSession: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.activeKeyWindow ?? ASPresentationAnchor()
    }
}
