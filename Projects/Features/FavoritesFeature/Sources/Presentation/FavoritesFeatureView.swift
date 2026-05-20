import SwiftUI

struct FavoritesFeatureView: View {
    private let compound: FavoritesFeatureCompound

    init(compound: FavoritesFeatureCompound) {
        self.compound = compound
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("FavoritesFeature")
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
