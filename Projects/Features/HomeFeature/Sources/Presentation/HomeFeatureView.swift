import Core
import SwiftUI

public struct HomeFeatureView: View {
    @Environment(HomeFeatureCoordinator.self) private var coordinator
    @State private var compound = HomeFeatureCompound()

    public init() {}

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
                coordinator.push(.search)
            }

            Button("팝업 상세로 이동") {
                coordinator.push(.popupDetail)
            }
        }
        .padding()
        .task {
            compound.send(.onAppear)
        }
    }
}
