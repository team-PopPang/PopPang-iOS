//
//  RootViewSwitcher.swift
//  DevNote
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

struct RootViewSwitcher: View {
    @StateObject var rootViewModel: RootViewModel
    @State private var coordinator = Coordinator<OnboardingRoute, SheetRoute>()

    init(rootViewModel: RootViewModel) {
        self._rootViewModel = StateObject(wrappedValue: rootViewModel)
        UINavigationBar.configureAppearance()
    }
    
    // MARK: - 각 파트의 Root View입니다
    var body: some View {
        Group {
            switch rootViewModel.scene {
                
            // MARK: - 앱시작 루트
            case .launch:
                LaunchView()
                
            // MARK: - 온보딩 + 로그인 루트
            case .unauthenticated:
                OnboadringView()
                    .environmentObject(coordinator)
            
            // MARK: - 회원가입 루트
            case .register:
                NicknameSettingView()
                
            // MARK: - 홈 루트
            case .authenticated:
                HomeView()
            }
        }
        .animation(.linear(duration: 0.3), value: rootViewModel.scene == .launch)
        .environmentObject(rootViewModel)
    }
}









//    enum RootScene {
//        case launch     // 시작
//        case onboarding // 온보딩
//        case auth       // 회원가입
//        case home       // 홈
//    }
