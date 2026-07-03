import ComposableArchitecture
import Core
import Domain
import ProfileFeature
import SwiftUI

@main
struct ProfileFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileFeatureView(
                store: Store(
                    initialState: ProfileFeature.State(
                        session: Shared(
                            value: UserSession(user: .demo)
                        )
                    )
                ) {
                    ProfileFeature()
                } withDependencies: {
                    $0.profileFeatureClient = ProfileFeatureClient(
                        checkNickname: { nickname in
                            nickname == "중복닉네임"
                        },
                        updateNickname: { _, _ in },
                        hardDeleteUser: { _ in },
                        alertStatus: { _, _ in }
                    )
                }
            )
        }
    }
}

private extension User {
    static let demo = User(
        userUuid: "demo-user",
        uid: "demo-user",
        provider: "KAKAO",
        email: nil,
        nickname: "홍길동",
        role: "USER",
        isAlerted: false,
        fcmToken: nil,
        alertKeywordList: nil,
        recommendList: nil
    )
}
