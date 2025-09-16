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
        await MainActor.run { updateScene()  }
    }

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

    func loginSuccess(isNewUser: Bool) {
        self.isLoggedIn = true
        self.hasProfile = !isNewUser
        self.updateScene()
    }

    func logout() {
        isLoggedIn = false
        hasProfile = false
        updateScene()
    }
}
