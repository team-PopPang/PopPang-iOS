import SwiftUI

public struct OnboardingFeatureView: View {
    @State private var compound = OnboardingFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("OnboardingFeature")
                .font(.title2)

            if compound.state.isLoading {
                ProgressView()
            }

            Button("새로고침") {
                compound.send(.refresh)
            }
        }
        .padding()
        .task {
            compound.send(.onAppear)
        }
    }
}
