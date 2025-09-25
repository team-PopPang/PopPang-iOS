//
//  KakaoLoginViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation
import Combine
import KakaoSDKAuth
import KakaoSDKUser

final class KakaoAuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    // 카카오 로그인
    func handleKakaoLogin() {
        Task {
            // 1. 카카오톡앱 설치 여부 확인
            if (UserApi.isKakaoTalkLoginAvailable()) {
                
                // 앱으로 로그인
                isLoggedIn = await handleWithKakaoApp()
            }
            
            // 2. 커카오톡앱 설치 안되어 있을 때
            else {
                // 웹뷰로 로그인
                isLoggedIn = await handleWithKakaoWeb()
            }
        }
    }
    
    // 카카오 로그아웃
    func kakaoLogout() {
        Task {
            if await handleKakaoLogout() {
                isLoggedIn = false
            }
        }
    }
}

extension KakaoAuthViewModel {
    // 카카오 앱으로 로그인
    @MainActor
    private func handleWithKakaoApp() async -> Bool {
        await withCheckedContinuation { continuation in
            // 앱으로 로그인
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                    continuation.resume(returning: false)
                }
                else {
                    print("loginWithKakaoTalk() success.")
                    // 성공 시 동작 구현
                    _ = oauthToken
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // 카카오 웹뷰로 로그인
    @MainActor
    private func handleWithKakaoWeb() async -> Bool {
        await withCheckedContinuation { continuation in
            // 웹뷰로 로그인
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                if let error = error {
                    print(error)
                    continuation.resume(returning: false)
                }
                else {
                    print("loginWithKakaoAccount() success.")
                    // 성공 시 동작 구현
                    _ = oauthToken
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // 카카오 로그아웃
    @MainActor
    private func handleKakaoLogout() async -> Bool {
        
        await withCheckedContinuation { continuation in
            UserApi.shared.logout {(error) in
                if let error = error {
                    print(error)
                    continuation.resume(returning: false)
                }
                else {
                    print("logout() success.")
                    continuation.resume(returning: true)
                }
            }
        }
    }
}
