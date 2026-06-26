import Domain
import MapFeatureInterface
import SwiftUI

public struct MapFeatureView: View {
    private let userUuid: String
    private let router: any MapFeatureRouting

    public init(
        userUuid: String = "demo-user",
        router: any MapFeatureRouting
    ) {
        self.userUuid = userUuid
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MapFeature")
                .font(.title.bold())
            Text("지도 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Button("팝업 상세 열기") {
                router.route(to: .popupDetail(.popupMock))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
