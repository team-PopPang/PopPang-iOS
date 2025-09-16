////
////  LoginView.swift
////  PopPang
////
////  Created by 김동현 on 9/14/25.
////
//
//import SwiftUI
//
//struct LoginView: View {
//    @EnvironmentObject var coordinator: Coordinator<OnboardingRoute, SheetRoute>
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            
//            Image("Logo Logo")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 200, height: 200)
//                
//            
//            VStack {
//                SocialLoginButton(type: .kakao) {
//                    print("카카오 로그인")
//                    coordinator.push(.nicknameSetting)
//                }
//                
//                SocialLoginButton(type: .apple) {
//                    print("애플 로그인")
//                }
//            }
//            .padding(.top, 50)
//        }
//        .padding(.horizontal, 10)
//    }
//}
//
//#Preview {
//    LoginView()
//}
//



import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var coordinator: Coordinator<OnboardingRoute, SheetRoute>
    @EnvironmentObject var rootViewModel: RootViewModel
    
    // ✅ Delegate, Presentation Provider를 프로퍼티로 유지해야 함
    private let appleDelegate = AppleLoginDelegate()
    private let applePresentationProvider = AppleLoginPresentationProvider()
    
    var body: some View {
        VStack(spacing: 0) {
            
            Image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                
            VStack {
                // ✅ 카카오
                SocialLoginButton(type: .kakao) {
                    print("카카오 로그인")
                    // coordinator.push(.nicknameSetting)
                    rootViewModel.loginSuccess(isNewUser: true)
                }
                
                // ✅ 커스텀 애플 로그인 버튼
                SocialLoginButton(type: .apple) {
                    handleAppleLogin()
                }
            }
            .padding(.top, 50)
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Apple 로그인 핸들러
    private func handleAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = appleDelegate // ✅ 프로퍼티로 유지되는 객체 사용
        controller.presentationContextProvider = applePresentationProvider
        controller.performRequests()
    }
}

#Preview {
    LoginView()
}

// MARK: - Delegate
final class AppleLoginDelegate: NSObject, ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let idToken = String(data: credential.identityToken ?? Data(), encoding: .utf8) ?? ""
            let authCode = String(data: credential.authorizationCode ?? Data(), encoding: .utf8) ?? ""
            
            print("🍎 Apple ID Token: \(idToken)")
            print("🍎 Apple Authorization Code: \(authCode)")
            
            // TODO: 서버로 전달
            sendToServer(idToken: idToken, code: authCode)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple login failed: \(error.localizedDescription)")
    }
    
    // MARK: - 서버 전송 함수
    private func sendToServer(idToken: String, code: String) {
        guard let url = URL(string: "https://index.zapto.org/api/redirect") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // ✅ application/x-www-form-urlencoded 방식으로 전송
        let bodyString = "id_token=\(idToken)&code=\(code)"
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 서버 요청 실패: \(error.localizedDescription)")
                return
            }
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                print("✅ 서버 응답: \(responseText)")
            }
        }.resume()
    }
}

// MARK: - PresentationContextProvider
final class AppleLoginPresentationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first!
    }
}
