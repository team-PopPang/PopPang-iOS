//
//  LoginView.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var coordinator: Coordinator<OnboardingRoute, SheetRoute>
    
    var body: some View {
        VStack(spacing: 0) {
            
            Image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                
            
            VStack {
                SocialLoginButton(type: .kakao) {
                    print("카카오 로그인")
                    coordinator.push(.nicknameSetting)
                }
                
                SocialLoginButton(type: .apple) {
                    print("애플 로그인")
                }
            }
            .padding(.top, 50)
        }
        .padding(.horizontal, 10)
    }
}

#Preview {
    LoginView()
}

