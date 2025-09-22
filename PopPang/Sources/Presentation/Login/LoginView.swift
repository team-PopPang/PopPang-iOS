//
//  LoginView.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI
import AuthenticationServices
import Combine

struct LoginView: View {
    @EnvironmentObject var coordinator: Coordinator<OnboardingRoute, SheetRoute>
    @EnvironmentObject var rootViewModel: RootViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            Image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                
            VStack {
                // MARK: - 카카오
                SocialLoginButton(type: .kakao) {
                    // rootViewModel.loginSuccess(isNewUser: true)
                    rootViewModel.send(action: .kakaoLogin)
                }
                
                // MARK: - 애플
                ZStack {
                    // MARK: - 실제 Apple 로그인 버튼
                    SignInWithAppleButton { request in
                        // 로그인 요청에 포함할 정보 지정
                        // print("request: \(request)")
                       
                    } onCompletion: { result in
                        // 로그인 시도가 끝났을 때 실행: Result<ASAuthorization, any Error>
                        // print("result: \(result)")
                        switch result {
                        case .success(let authorization):
                            rootViewModel.send(action: .appleLogin(authorization))
                        case .failure(let error):
                            print("[LoginView] 애플 로그인 에러: \(error.localizedDescription)")
                        }
                        
                    }
                    .frame(maxWidth: 375, maxHeight: 52)
                    
                    // ✅ 커스텀 애플 로그인 버튼
                    SocialLoginButton(type: .apple) {
                        // rootViewModel.loginSuccess(isNewUser: false)
                        // rootViewModel.send(action: .appleLogin)
                        triggerAppleLoginBtnTap()
                    }
                }
            }
            .padding(.top, 50)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 애플 버튼 트리거
extension LoginView {
    
    // MARK: - 커스텀 애플 버튼을 누르면 실제 애플 로그인 버튼을 누르도록 트리거 하는 함수
    // Apple 로그인 버튼을 찾고 동작 트리거
    private func triggerAppleLoginBtnTap() {
        guard let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }),
              let appleButton = findAppleSignInButton(in: keyWindow) else {
            print("Apple 로그인 버튼을 찾을 수 없습니다.")
            return
        }
        
        // 버튼 액션 강제 실행
        appleButton.sendActions(for: .touchUpInside)
    }
    
    private func findAppleSignInButton(in view: UIView) -> ASAuthorizationAppleIDButton? {
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

#Preview {
    LoginView()
        .environmentObject(RootViewModel())
}
