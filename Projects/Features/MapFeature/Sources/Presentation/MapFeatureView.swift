import SwiftUI

struct MapFeatureView: View {
    private let compound: MapFeatureCompound

    init(compound: MapFeatureCompound) {
        self.compound = compound
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("MapFeature")
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
