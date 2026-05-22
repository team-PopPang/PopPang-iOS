import SwiftUI

public struct AlertFeatureView: View {
    @State private var compound = AlertFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("AlertFeature")
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
