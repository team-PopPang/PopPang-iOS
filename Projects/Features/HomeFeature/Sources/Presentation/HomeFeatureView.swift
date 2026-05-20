import SwiftUI

struct HomeFeatureView: View {
    private let compound: HomeFeatureCompound

    init(compound: HomeFeatureCompound) {
        self.compound = compound
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("HomeFeature")
                .font(.title2)

            if compound.state.isLoading {
                ProgressView()
            }

            Button("새로고침") {
                compound.send(.refresh)
            }

            Button("검색으로 이동") {
                compound.send(.searchButtonTapped)
            }

            Button("팝업 상세로 이동") {
                compound.send(.popupDetailButtonTapped)
            }
        }
        .padding()
        .task {
            compound.send(.onAppear)
        }
    }
}
