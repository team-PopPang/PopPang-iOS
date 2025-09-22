//
//  RootViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import AuthenticationServices

enum RootScene {
    case launch
    case unauthenticated   // 온보딩/로그인
    case register          // 회원가입
    case authenticated     // 홈
}

final class RootViewModel: ObservableObject {
    
    enum Action {
        case kakaoLogin
        case appleLogin(ASAuthorization)
    }
    
    @Dependency private var appleLoginUsecase: AppleLoginUsecaseProtocol
    @Published var scene: RootScene = .launch
    @Published var user: User? = nil
    
    init() {
        Task {
            await boot()
        }
    }
    
    func boot() async {
        print("로그인 인증 진행")
        
        // 1. 실제 비동기 로직 (서버 인증 요청)
        
        // 2. launch뷰 로딩 시간(1초 보장)
        try? await Task.sleep(for: .seconds(1))
        
        // 3. 인증 결과에 따른 화면 업데이트
        await MainActor.run { updateScene() }
        /*
        await MainActor.run {
            loginSuccess(isNewUser: false)
        }
         */
        
        print("로그인 인증 진행 완료")
    }
}

// MARK: - 인증 로직
extension RootViewModel {
    func send(action: Action) {
        switch action {
        case .kakaoLogin:
            print("카카오 로그인")
            self.user = User(uid: "1",
                             email: nil,
                             role: "member",
                             provider: "kakao", recommands: [])
            self.user = User(uid: "1",
                             email: nil,
                             nickname: "index",
                             role: "member",
                             provider: "kakao", recommands: [])
            updateScene()
            
        case .appleLogin(let authorization):
            print("애플 로그인")
            Task {
                do {
                    let user = try await appleLoginUsecase.appleLogin(authorization: authorization)
                    print("user: \(user)")
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch {
                    print("❌ 애플 로그인 실패")
                }
            }
        }
    }
}

// MARK: - 화면 전환 로직
/// 버튼 액션이나 UI 이벤트에서 호출되므로 메인스레드에서 실행되므로 감쌀 필요 x
extension RootViewModel {
    
    // 화면 업데이트
    func updateScene() {
        // 비로그인
        guard let user else {
            scene = .unauthenticated
            return
        }
        // 신규 유저
        if user.nickname == nil {
            scene = .register
        }
        // 기존 유저
        else {
            scene = .authenticated
        }
    }
}

// MARK: - 로그인 관련 로직
extension RootViewModel {
    // 로그인 완료
    func loginSuccess(user: User) {
        self.user = user
        self.updateScene()
    }

    // 로그아웃
    func logout() {
        user = nil
        updateScene()
    }
    
    // 닉네임 설정
    func updateNickname(_ nickname: String) {
        guard var currentUser = user else { return }
        currentUser.nickname = nickname
        self.user = currentUser
    }
    
    // 추천키워드 설정
    func updateKeywords(_ keywords: [String]) {
        guard var currentUser = user else { return }
        currentUser.recommands = keywords
        self.user = currentUser
    }
    
    
    // 서버에 최종 반영
    func completeRegistration() {
        guard let currentUser = user,
                  currentUser.nickname != nil
                  // ,!currentUser.recommands.isEmpty
        else {
            print("❌ 필수 정보가 비어있습니다.")
            return
        }
        print(currentUser)
        
        /*
        // 1. 서버 업데이트 요청
        do {
            
            let updatedUser = try await UserAPI.updateUser(
                uid: currentUser.uid,
                nickname: nickname,
                category: category
            )
            
            // 2. 서버 응답값을 반영
            self.user = updatedUser
            updateScene()
             
        } catch {
            
        }
         */
        
        self.user = user
        self.updateScene()
    }
}
