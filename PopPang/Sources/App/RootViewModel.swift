//
//  RootViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import Combine

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
    
    // @Dependency private var userSession: UserSessionProtocol
    
    // MARK: - Keychain으로 변환 예정
    @AppStorage("uuid") private var storeUID: String = ""
    
    // MARK: - Action
    enum Action {
        case autoLogin
        case kakaoLogin
        case googleLogin
        case appleLogin(ASAuthorization)
        case checkNickname
        case setalertList([String])              // 알림 키워드 설정
        case setIsAlertedUser(Bool)                  // 알림 권한 허용시 회원가입 유저 isAlerted도 적용
        case setRecommandList([Int])             // 추천 키워드 설정
        case register                            // 화원가입
        case logout
        case checkFcmToken(String)
    }
    
    // MARK: - Dependency
    @Dependency private var appleAuthUsecase: AppleAuthUsecaseProtocol
    @Dependency private var kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    @Dependency private var googleAuthUsecase: GoogleAuthUsecaseProtocol
    @Dependency private var userUsecase: UserUsecaseProtocol
    
    // MARK: - Scene
    @Published var scene: RootScene = .launch
    
    // MARK: - User
    @Published var user: User? = nil
    @Published var googleResponseDTO = GoogleResponseDTO()
    
    // MARK: - NicknameSetting
    @Published var validationState: NicknameValidationState = .none
    
    // MARK: - 회원가입 or 프로필 세팅에서 닉네임 수정시 사용
    @Published var nickname: String = "" {
        didSet {
            self.checkLocalNickname()
        }
    }
    
    // MARK: - RecommandList
    @Published var recommandList: [RecommendList] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
        Task {
            await boot()
        }
    }
    
    func boot() async {
        // print("로그인 인증 진행")
        
        // 1. 실제 비동기 로직 (서버 인증 요청)
        await MainActor.run {
            self.send(action: .autoLogin)
        }
        
        // 2. launch뷰 로딩 시간(1초 보장)
        try? await Task.sleep(for: .seconds(1))
        
        // 3. 인증 결과에 따른 화면 업데이트
        await MainActor.run { updateScene() }
        // Logger.d("로그인 인증 진행 완료")
    }
}

// MARK: - 인증 로직
extension RootViewModel {
    func send(action: Action) {
        switch action {
        // MARK: - 자동 로그인
        case .autoLogin:
            if !storeUID.isEmpty {
                Task {
                    do {
                        let user = try await userUsecase.autoLogin(userUuid: storeUID)
                        await MainActor.run {
                            self.loginSuccess(user: user)
                            Logger.d("자동로그인 성공\n")
                            // userSession.setUser(user)
                        }
                        
                    } catch (let error) {
                        Logger.e("❌ 자동 로그인 실패: \(error)")
                        await MainActor.run {
                            self.user = nil
                            self.scene = .unauthenticated
                        }
                    }
                }
            }
            
        // MARK: - 카카오 로그인
        case .kakaoLogin:
            print("카카오 로그인")
            Task {
                do {
                    let user = try await kakaoAuthUsecase.kakaoLogin()
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch (let error) {
                    Logger.e("❌ 카카오 로그인 실패: \(error)")
                }
            }
            
        // MARK: - 애플 로그인
        case .appleLogin(let authorization):
            print("애플 로그인")
            Task {
                do {
                    let user = try await appleAuthUsecase.appleLogin(authorization: authorization)
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch (let error) {
                    Logger.e("❌ 애플 로그인 실패: \(error)")
                }
            }
            
        // MARK: - 구글 로그인
        case .googleLogin:
            print("구글 로그인")
            Task {
                do {
                    let user = try await googleAuthUsecase.googleLogin()
                    await MainActor.run {
                        self.loginSuccess(user: user)
                    }
                } catch (let error) {
                    Logger.e("❌ 구글 로그인 실패: \(error)")
                }
            }
            
        // MARK: - 닉네임 중복확인
        case .checkNickname:
            
            // 닉네임이 빈값이면 서버 안탐
            guard !nickname.isEmpty else { return }
            
            switch validationState {
            case .invalidSpace, .tooShort: return // 로컬에서 이미 실패 상태면 서버 안탐
            default: break                        // 그 외에는 허용
            }
            
            // 확인중
            validationState = .checking
            
            Task {
                do {
                    let isDuplicated = try await userUsecase.checkNickname(nickname: nickname)
                    await MainActor.run {
                        self.validationState = isDuplicated ? .duplicate : .success
                        
                        // MARK: - 만약 success이면 회원가입에 적용할 User속성에 추가한다
                        if self.validationState == .success {
                            precondition(user != nil, "⚠️ 회원가입 단계에서는 user가 nil일 수 없음")
                            var registerUser = user!
                            registerUser.nickname = self.nickname
                            self.user = registerUser
                        }
                    }
                } catch {
                    Logger.e("❌ 중복 확인 실패: \(error)")
                }
            }
            
        // MARK: - 알림 키워드 세팅
        case .setalertList(let alertList):
            var registerUser = user!
            registerUser.alertKeywordList = alertList
            self.user = registerUser
            Logger.d("알림 키워드 적용됨: \(self.user!)")
            
        // MARK: - isAlerted 설정
        case .setIsAlertedUser(let alertAuth):
            var registerUser = user!
            registerUser.isAlerted = alertAuth
            self.user = registerUser
            Logger.d("알림 권한 적용됨: \(self.user!)")
            
        // MARK: - 추천 키워드 세팅
        case .setRecommandList(let recommandList):
            var registerUser = user!
            registerUser.recommendList = recommandList
            self.user = registerUser
            Logger.d("추천 키워드 적용됨: \(self.user!)")
            
        // MARK: - 회원가입 완료 버튼
        case .register:
            
            guard var registerUser = user else { return }
            
            // 알림 키워드 nil이면 빈배열로
            if registerUser.alertKeywordList == nil {
                registerUser.alertKeywordList = []
            }
            
            // 추천 키워드 nil이면 빈배열로
            if registerUser.recommendList == nil {
                registerUser.recommendList = []
            }
            
            switch registerUser.provider {
            case "APPLE":
                Task {
                    do {
                        let newUser = try await appleAuthUsecase.appleRegister(user: registerUser)
                        await MainActor.run {
                            self.loginSuccess(user: newUser)
                            self.user = newUser
                        }
                    } catch (let error) {
                        Logger.e("❌ 애플 회원가입 실패: \(error)")
                    }
                }
                
            case "KAKAO":
                Task {
                    do {
                        let newUser = try await kakaoAuthUsecase.kakaoRegister(user: registerUser)
                        await MainActor.run {
                            self.loginSuccess(user: newUser)
                            self.user = newUser
                        }
                    } catch (let error) {
                        Logger.e("❌ 카카오 회원가입 실패: \(error)")
                    }
                }
                
            case "GOOGLE":
                Task {
                    do {
                        let newUser = try await googleAuthUsecase.googleRegister(user: registerUser)
                        await MainActor.run {
                            self.loginSuccess(user: newUser)
                            self.user = newUser
                        }
                    } catch (let error) {
                        Logger.e("❌ 구글 회원가입 실패: \(error)")
                    }
                }
                
            default:
                break
            }
            
        case .logout:
            logout()
            
        case .checkFcmToken(let localFcmToken):
            Task {
                do {
                    guard let userUuid = user?.userUuid else {
                        Logger.w("⚠️ uuid 없음")
                        return
                    }

                    let fcmTokenResult = try await userUsecase.checkFcmToken(userUuid:userUuid,
                                                                             fcmToken: localFcmToken)
                    
                    // fcm토큰이 일치하지 않거나 로컬에 존재하지 않는다면
                    if !fcmTokenResult {
                        try await userUsecase.updateFcmToken(userUuid: userUuid, fcmToken: localFcmToken)
                        Logger.d("로컬 FCM 토큰을 서버로 전송 및 갱신 완료")
                    }
                } catch {
                    Logger.e("❌ FCM 토큰 중복 확인 실패: \(error)")
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
            
            Task {
                await getRecommandList()
            }
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
    private func checkLocalNickname() {
        
        // 미검증
        guard !nickname.isEmpty else {
            validationState = .none
            return
        }
        
        // 공백여부
        if nickname.contains(" ") {
            validationState = .invalidSpace
            return
        }
        
        if nickname.count <= 2 {
            validationState = .tooShort
            return
        }
        
        // 아직 서버 검증 전 단계
        validationState = .none
    }
}

// MARK: - 추천 리스트(회원가입 마지막)
extension RootViewModel {
    // 추천 리스트 불러오기
    private func getRecommandList() async {
        do {
            let response = try await userUsecase.getRecommandList()
            await MainActor.run {
                self.recommandList = response
            }
            // Logger.d("✅ recommandList: \(recommandList)")
        } catch {
            Logger.e("❌ recommandList Error: \(error)")
        }
    }
}

// MARK: - 로그인 관련 로직
extension RootViewModel {
    // 로그인 완료
    func loginSuccess(user: User) {
        self.user = user
        self.storeUID = user.userUuid
        self.updateScene()
        
        // 이전 구독 제거 (중복 방지)
        cancellables.removeAll()
        
        // fcm토큰 확인 및 갱신 로직
        NotificationManager.shared.$fcmToken
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                guard let self = self else { return }
                self.send(action: .checkFcmToken(token))
            }
            .store(in: &cancellables)
    }

    // 로그아웃
    func logout() {
        self.user = nil
        self.storeUID = ""
        self.nickname = ""
        self.validationState = .none
        self.scene = .unauthenticated
        self.updateScene()
    }
}

