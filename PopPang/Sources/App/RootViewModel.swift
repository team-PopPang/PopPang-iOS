//
//  RootViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

enum RootScene {
    case launch
    case unauthenticated   // 온보딩/로그인
    case register          // 회원가입
    case authenticated     // 홈
}

final class RootViewModel: ObservableObject {
    
    enum Action {
        case kakaoLogin
        case appleLogin
    }
    
    @Published var scene: RootScene = .launch
    private var isLoggedIn: Bool = false    // 로그인 유무
    private var hasProfile: Bool = false    // 로그인 후 기존 유저 유무
    
    init() {
        Task { await boot() }
    }
    
    func boot() async {
        await DIContainer.config()
        
        // launch뷰 로딩 시간
        try? await Task.sleep(for: .seconds(1))
        
        // 준비 끝난 후 루트 뷰 전환
        await MainActor.run { updateScene() }
    }
}

// MARK: - 인증 로직
extension RootViewModel {
    func send(action: Action) {
        switch action {
        case .kakaoLogin:
            print("카카오 로그인")
        case .appleLogin:
            print("애플 로그인")
        }
    }
}

// MARK: - 화면 전환 로직
/// 버튼 액션이나 UI 이벤트에서 호출되므로 메인스레드에서 실행되므로 감쌀 필요 x
extension RootViewModel {
    
    // 화면 업데이트
    func updateScene() {
        // 비로그인
        if !isLoggedIn {
            scene = .unauthenticated
        }
        // 신규 유저
        else if !hasProfile {
            scene = .register
        }
        // 기존 유저
        else {
            scene = .authenticated
        }
    }
    
    // 로그인 완료
    func loginSuccess(isNewUser: Bool) {
        self.isLoggedIn = true
        self.hasProfile = !isNewUser
        self.updateScene()
    }
    
    // 가입 완료
    func completeRegistration() {
        self.hasProfile = true
        self.updateScene()
    }

    // 로그아웃
    func logout() {
        isLoggedIn = false
        hasProfile = false
        updateScene()
    }
}
