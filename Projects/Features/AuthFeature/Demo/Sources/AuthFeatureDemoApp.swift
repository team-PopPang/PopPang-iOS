import AuthFeature
import ComposableArchitecture
import Domain
import SwiftUI

@main
struct AuthFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AuthFeatureView(
                store: Store(
                    initialState: AuthFeature.State()
                ) {
                    AuthFeature()
                } withDependencies: {
                    $0.authFeatureClient = AuthFeatureClient(
                        login: { provider in
                            // 카카오는 가입이 필요한 사용자, 나머지는 가입을 마친 사용자로 흉내 낸다
                            provider == .kakao ? .pending(provider) : .completed(.demo(provider: provider))
                        },
                        signup: { provider, request in
                            var user = User.demo(provider: provider)
                            user.nickname = request.nickname
                            return user
                        },
                        checkNickname: { _ in false },
                        getRecommendList: {
                            [
                                Recommend(id: 1, recommendName: "패션"),
                                Recommend(id: 2, recommendName: "뷰티"),
                                Recommend(id: 3, recommendName: "푸드"),
                                Recommend(id: 4, recommendName: "캐릭터"),
                                Recommend(id: 5, recommendName: "라이프스타일"),
                            ]
                        }
                    )
                }
            )
        }
    }
}

private extension User {
    static func demo(provider: Provider) -> User {
        User(
            userUuid: "demo-\(provider.rawValue.lowercased())",
            provider: provider,
            email: nil,
            nickname: "데모유저",
            role: .member,
            isAlerted: false
        )
    }
}
