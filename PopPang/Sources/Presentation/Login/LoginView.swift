//
//  LoginView.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI
import AuthenticationServices

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
                // ✅ 카카오
                SocialLoginButton(type: .kakao) {
                    // rootViewModel.loginSuccess(isNewUser: true)
                    rootViewModel.send(action: .kakaoLogin)
                }
                
                // ✅ 커스텀 애플 로그인 버튼
                SocialLoginButton(type: .apple) {
                    // rootViewModel.loginSuccess(isNewUser: false)
                    rootViewModel.send(action: .appleLogin)
                }
            }
            .padding(.top, 50)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    LoginView()
}
