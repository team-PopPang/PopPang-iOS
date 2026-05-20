import SwiftUI

struct PopupDetailFeatureView: View {
    private let compound: PopupDetailFeatureCompound

    init(compound: PopupDetailFeatureCompound) {
        self.compound = compound
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("PopupDetailFeature")
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
