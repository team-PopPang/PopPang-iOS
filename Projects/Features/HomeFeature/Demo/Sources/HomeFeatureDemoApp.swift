import ComposableArchitecture
import Core
import Domain
import HomeFeature
import SwiftUI

@main
struct HomeFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            HomeFeatureView(
                store: Store(
                    initialState: HomeFeature.State(
                        session: Shared(
                            UserSession(
                                user: User(
                                    userUuid: "demo-user",
                                    uid: "demo-uid",
                                    provider: "preview",
                                    email: nil,
                                    nickname: "팝팡",
                                    role: "ADMIN",
                                    isAlerted: false,
                                    fcmToken: nil,
                                    alertKeywordList: nil,
                                    recommendList: nil
                                )
                            )
                        )
                    )
                ) {
                    HomeFeature()
                } withDependencies: {
                    $0.homePopupClient = .previewValue
                }
            )
        }
    }
}
