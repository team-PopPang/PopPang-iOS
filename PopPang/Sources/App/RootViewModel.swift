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

enum NicknameValidationState {
    case none          // 미검증
    case success       // 사용가능
    case duplicate     // 중복
    case invalidSpace  // 공백 불가
    case checking      // 확인중
    case tooShort      // 글자 길이 짧음
}

final class RootViewModel: ObservableObject {
    
    enum Action {
        case kakaoLogin
        case appleLogin(ASAuthorization)
    }
    
    @Dependency private var appleLoginUsecase: AppleAuthUsecaseProtocol
    @Dependency private var kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    @Published var scene: RootScene = .launch
    @Published var user: User? = nil
    
    // MARK: - NicknameSetting
    @Published var nickname: String = "" {
        didSet {
            checkLocalNickname(value: nickname)
        }
    }
    @Published var validationState: NicknameValidationState = .none
    
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
            Task {
                do {
                    let user = try await kakaoAuthUsecase.kakaoLogin()
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch (let error) {
                    print("❌ 카카오 로그인 실패: \(error)")
                }
            }
            // updateScene()
            
        case .appleLogin(let authorization):
            print("애플 로그인")
            Task {
                do {
                    let user = try await appleLoginUsecase.appleLogin(authorization: authorization)
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch (let error) {
                    print("❌ 애플 로그인 실패: \(error)")
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

// MARK: - 닉네임뷰
extension RootViewModel {
    
    // 로컬 검증 로직
    private func checkLocalNickname(value: String) {
        
        // 미검증
        guard !value.isEmpty else {
            validationState = .none
            return
        }
        
        // 공백여부
        if value.contains(" ") {
            validationState = .invalidSpace
            return
        }
        
        if value.count <= 2 {
            validationState = .tooShort
            return
        }
        
        // 아직 서버 검증 전 단계
        validationState = .none
    }
    
    // 서버 검증 로직
    func checkServerNickname() {
        // 로컬에서 이미 실패 상태면 서버 안탐
        switch validationState {
        case .invalidSpace, .tooShort:
            return
        default:
            break
        }
        
        // 서버에서 중복 여부
        validationState = .checking
        
        Task {
            // 서버 흉내(1초 지연)
            try? await Task.sleep(for: .seconds(1))
            
            // 서버 응답 흉내
            let isDuplicate = nickname.lowercased() == "admin"
            
            await MainActor.run {
                self.validationState = isDuplicate ? .duplicate : .success
            }
        }
    }
    
    // 닉네임 설정(다음 버튼)
    func updateNickname() {
        guard var currentUser = user else { return }
        currentUser.nickname = nickname
        self.user = currentUser
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
        self.user = nil
        updateScene()
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
