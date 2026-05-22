import SwiftUI

public struct ProfileFeatureView: View {
    @State private var compound = ProfileFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("ProfileFeature")
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
