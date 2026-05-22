import SwiftUI

public struct ReviewFeatureView: View {
    @State private var compound = ReviewFeatureCompound()

    public init() {}

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
