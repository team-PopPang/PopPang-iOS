import SwiftUI

struct OnboardingFeatureView: View {
    private let compound: OnboardingFeatureCompound

    init(compound: OnboardingFeatureCompound) {
        self.compound = compound
    }

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
