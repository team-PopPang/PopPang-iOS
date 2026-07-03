import ComposableArchitecture
import ReviewFeature
import SwiftUI

@main
struct ReviewFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ReviewFeatureView(
                store: Store(
                    initialState: ReviewFeature.State()
                ) {
                    ReviewFeature()
                }
            )
        }
    }
}
