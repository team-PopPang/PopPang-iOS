import ComposableArchitecture
import OnboardingFeatureV2
import SwiftUI

@main
struct OnboardingFeatureV2DemoApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingFeatureView(
                store: Store(
                    initialState: OnboardingFeature.State()
                ) {
                    OnboardingFeature()
                }
            )
        }
    }
}
