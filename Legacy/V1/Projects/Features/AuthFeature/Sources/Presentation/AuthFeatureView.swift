import AuthenticationServices
import Domain
import DSKit
import SwiftUI
import UIKit

public struct AuthFeatureView: View {
    @State private var compound: AuthFeatureCompound

    public init(
        onLoginSuccess: @escaping @MainActor (User) -> Void = { _ in }
    ) {
        _compound = State(
            wrappedValue: AuthFeatureCompound(
                onLoginSuccess: onLoginSuccess
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            DSKitResource.image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)

            VStack {
                SocialLoginButton(type: .kakao) {
                    compound.send(.kakaoLogin)
                }

                ZStack {
                    SignInWithAppleButton { _ in
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            compound.send(.appleLogin(.init(authorization)))
                        case .failure(let error):
                            print("[LoginView] 애플 로그인 에러: \(error.localizedDescription)")
                        }
                    }
                    .frame(maxWidth: 375, maxHeight: 52)

                    SocialLoginButton(type: .apple) {
                        triggerAppleLoginBtnTap()
                    }
                }

                SocialLoginButton(type: .google) {
                    compound.send(.googleLogin)
                }
            }
            .padding(.top, 120)
        }
        .padding(.horizontal, 24)
    }
}

private extension AuthFeatureView {
    func triggerAppleLoginBtnTap() {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
            let appleButton = findAppleSignInButton(in: keyWindow)
        else {
            print("Apple 로그인 버튼을 찾을 수 없습니다.")
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
