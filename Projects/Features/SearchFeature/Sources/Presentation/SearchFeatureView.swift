import SwiftUI

public struct SearchFeatureView: View {
    @State private var compound = SearchFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("SearchFeature")
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
