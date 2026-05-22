import AuthenticationServices
import Domain
import DSKit
import SwiftUI
import UIKit

public struct AuthFeatureView: View {
    private let kakaoLogin: (@MainActor () async throws -> User)?
    private let googleLogin: (@MainActor () async throws -> User)?
    private let appleLogin: (@MainActor (ASAuthorization) async throws -> User)?
    private let onLoginSuccess: (User) -> Void

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    public init(
        kakaoLogin: (@MainActor () async throws -> User)? = nil,
        googleLogin: (@MainActor () async throws -> User)? = nil,
        appleLogin: (@MainActor (ASAuthorization) async throws -> User)? = nil,
        onLoginSuccess: @escaping (User) -> Void = { _ in }
    ) {
        self.kakaoLogin = kakaoLogin
        self.googleLogin = googleLogin
        self.appleLogin = appleLogin
        self.onLoginSuccess = onLoginSuccess
    }

    public var body: some View {
        VStack(spacing: 0) {
            Image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)

            VStack {
                SocialLoginButton(type: .kakao) {
                    submit(.kakao)
                }
                .disabled(isSubmitting)

                ZStack {
                    SignInWithAppleButton { _ in
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            submitApple(authorization)
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                    .frame(maxWidth: 375, maxHeight: 52)
                    .disabled(isSubmitting)

                    SocialLoginButton(type: .apple) {
                        triggerAppleLoginBtnTap()
                    }
                    .disabled(isSubmitting)
                }

                SocialLoginButton(type: .google) {
                    submit(.google)
                }
                .disabled(isSubmitting)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainRed)
                        .padding(.top, 8)
                }
            }
            .padding(.top, 120)
        }
        .padding(.horizontal, 24)
    }

    private func submit(_ provider: SocialProvider) {
        isSubmitting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let user: User
                switch provider {
                case .kakao:
                    if let kakaoLogin {
                        user = try await kakaoLogin()
                    } else {
                        user = demoUser(provider: provider)
                    }
                case .google:
                    if let googleLogin {
                        user = try await googleLogin()
                    } else {
                        user = demoUser(provider: provider)
                    }
                case .apple:

                }

                isSubmitting = false
                onLoginSuccess(user)
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitApple(_ authorization: ASAuthorization) {
        isSubmitting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let user: User
                if let appleLogin {
                    user = try await appleLogin(authorization)
                } else {
                    user = demoUser(provider: .apple)
                }
                isSubmitting = false
                onLoginSuccess(user)
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func demoUser(provider: SocialProvider) -> User {
        User(
            userUuid: "demo-\(provider.rawValue)",
            uid: "demo-\(provider.rawValue)",
            provider: provider.rawValue.uppercased(),
            email: nil,
            nickname: "데모유저",
            role: "USER",
            isAlerted: false,
            fcmToken: nil,
            alertKeywordList: nil,
            recommendList: nil
        )
    }
}

private extension AuthFeatureView {
    func triggerAppleLoginBtnTap() {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow),
            let appleButton = findAppleSignInButton(in: keyWindow)
        else {
            return
        }

        appleButton.sendActions(for: .touchUpInside)
    }

    func findAppleSignInButton(in view: UIView) -> ASAuthorizationAppleIDButton? {
        for subview in view.subviews {
            if let appleButton = subview as? ASAuthorizationAppleIDButton {
                return appleButton
            }
            if let found = findAppleSignInButton(in: subview) {
                return found
            }
        }
        return nil
    }
}

private enum SocialProvider: String {
    case kakao
    case apple
    case google
}
