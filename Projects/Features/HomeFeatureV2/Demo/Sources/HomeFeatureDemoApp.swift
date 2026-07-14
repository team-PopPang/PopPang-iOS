import ComposableArchitecture
import Domain
import HomeFeatureV2
import SwiftUI

@main
struct HomeFeatureV2DemoApp: App {
    var body: some Scene {
        WindowGroup {
            HomeFeatureView(
                store: Store(
                    initialState: HomeFeature.State(
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
                ) {
                    HomeFeature()
                } withDependencies: {
                    $0.homePopupClient = .previewValue
                }
            )
        }
    }
}
