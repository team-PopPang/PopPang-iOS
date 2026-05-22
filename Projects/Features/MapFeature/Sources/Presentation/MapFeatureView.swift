import Core
import SwiftUI

public struct MapFeatureView: View {
    @Environment(MapFeatureCoordinator.self) private var coordinator
    @State private var compound = MapFeatureCompound()

    public init() {}

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

            Button("목록 바텀시트 열기") {
                coordinator.presentBottomSheet(.popupList)
            }

            Button("상세 바텀시트 열기") {
                coordinator.presentBottomSheet(.popupDetail)
            }

            Button("바텀시트 닫기") {
                coordinator.dismissBottomSheet()
            }
        }
        .padding()
        .task {
            compound.send(.onAppear)
        }
    }
}
