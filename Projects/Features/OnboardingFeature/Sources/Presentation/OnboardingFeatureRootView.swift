import SwiftUI

public struct OnboardingFeatureRootView: View {
    @State private var compound = OnboardingFeatureCompound()

    public init() {}

    public var body: some View {
        OnboardingFeatureView(compound: compound)
    }
}
