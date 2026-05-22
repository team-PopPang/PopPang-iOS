import SwiftUI

public struct AuthFeatureView: View {
    @State private var compound = AuthFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("AuthFeature")
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
