import ComposableArchitecture
import OnboardingFeature
import SwiftUI

@main
struct OnboardingFeatureDemoApp: App {
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
