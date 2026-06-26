import Domain
import FavoritesFeatureInterface
import SwiftUI

public struct FavoritesFeatureView: View {
    private let userUuid: String
    private let router: any FavoritesFeatureRouting

    public init(
        userUuid: String = "demo-user",
        router: any FavoritesFeatureRouting
    ) {
        self.userUuid = userUuid
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FavoritesFeature")
                .font(.title.bold())
            Text("찜 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Button("알림 화면 열기") {
                router.route(to: .alert)
            }
            .buttonStyle(.bordered)
            Button("팝업 상세 열기") {
                router.route(to: .popupDetail(.popupMock))
            }
            .buttonStyle(.borderedProminent)
            Button("탐색 탭으로 이동") {
                router.route(to: .selectHomeTab)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
