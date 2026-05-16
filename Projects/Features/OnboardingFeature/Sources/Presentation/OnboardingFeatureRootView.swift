import SwiftUI

public struct OnboardingFeatureRootView: View {
    public init() {}

    public var body: some View {
        OnboardingFeatureView(
            store: OnboardingFeatureStore()
        )
    }
}
