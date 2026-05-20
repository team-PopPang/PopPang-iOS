import SwiftUI

struct ReviewFeatureView: View {
    private let compound: ReviewFeatureCompound

    init(compound: ReviewFeatureCompound) {
        self.compound = compound
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("ReviewFeature")
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
