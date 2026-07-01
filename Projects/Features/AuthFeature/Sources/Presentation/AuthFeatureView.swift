import AuthenticationServices
import ComposableArchitecture
import Domain
import DSKit
import SwiftUI
import UIKit

public struct AuthFeatureView: View {
    let store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DSKitResource.image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)

            VStack {
                SocialLoginButton(type: .kakao) {
                    store.send(.kakaoLoginTapped)
                }
                .disabled(store.isSubmitting)

                ZStack {
                    SignInWithAppleButton { _ in
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            store.send(.appleLoginTapped(.init(authorization)))
                        case .failure(let error):
                            print("[LoginView] 애플 로그인 에러: \(error.localizedDescription)")
                        }
                    }
                    .frame(maxWidth: 375, maxHeight: 52)
                    .disabled(store.isSubmitting)

                    SocialLoginButton(type: .apple) {
                        triggerAppleLoginBtnTap()
                    }
                    .disabled(store.isSubmitting)
                }

                SocialLoginButton(type: .google) {
                    store.send(.googleLoginTapped)
                }
                .disabled(store.isSubmitting)
            }
            .padding(.top, 120)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 24)
            }
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
