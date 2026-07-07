import AuthFeature
import AuthenticationServices
import Domain
import SwiftUI

@main
struct AuthFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(MockKakaoAuthUsecase(), for: KakaoAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockGoogleAuthUsecase(), for: GoogleAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockAppleAuthUsecase(), for: AppleAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockUserUsecase(), for: UserUsecaseProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            AuthFeatureView()
        }
    }
}

private final class MockKakaoAuthUsecase: KakaoAuthUsecaseProtocol {
    func kakaoLogin() async throws -> User {
        User.demo(provider: "KAKAO")
    }

    func kakaoRegister(user: User) async throws -> User {
        user
    }
}

private final class MockGoogleAuthUsecase: GoogleAuthUsecaseProtocol {
    func googleLogin() async throws -> User {
        User.demo(provider: "GOOGLE")
    }

    func googleRegister(user: User) async throws -> User {
        user
    }
}

private final class MockAppleAuthUsecase: AppleAuthUsecaseProtocol {
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        User.demo(provider: "APPLE")
    }

    func appleRegister(user: User) async throws -> User {
        user
    }
}

private final class MockUserUsecase: UserUsecaseProtocol {
    func checkNickname(nickname: String) async throws -> Bool {
        false
    }

    func autoLogin(userUuid: String) async throws -> User {
        User.demo(provider: "KAKAO")
    }

    func getRecommandList() async throws -> [Recommend] {
        [
            Recommend(id: 1, recommendName: "패션"),
            Recommend(id: 2, recommendName: "뷰티"),
            Recommend(id: 3, recommendName: "푸드"),
            Recommend(id: 4, recommendName: "캐릭터"),
            Recommend(id: 5, recommendName: "라이프스타일"),
        ]
    }

    func hardDeleteUser(userUuid: String) async throws {}
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword] { [] }
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {}
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {}
    func alertStatus(userUuid: String, isAlerted: Bool) async throws {}
    func updateNickname(userUuid: String, newNickname: String) async throws {}
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool { true }
    func updateFcmToken(userUuid: String, fcmToken: String) async throws {}
}

private extension User {
    static func demo(provider: String) -> User {
        User(
            userUuid: "demo-\(provider.lowercased())",
            uid: "demo-\(provider.lowercased())",
            provider: provider,
            email: nil,
            nickname: "데모유저",
            role: "USER",
            isAlerted: false,
            fcmToken: nil,
            alertKeywordList: nil,
            recommendList: nil
        )
    }
}
