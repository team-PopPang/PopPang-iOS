import ComposableArchitecture
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
                        userUuid: "demo-user",
                        nickname: "팝팡",
                        isAdmin: true
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
