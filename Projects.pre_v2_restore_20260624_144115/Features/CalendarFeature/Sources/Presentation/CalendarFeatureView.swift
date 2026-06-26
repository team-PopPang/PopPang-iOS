import Domain
import CalendarFeatureInterface
import SwiftUI

public struct CalendarFeatureView: View {
    private let userUuid: String
    private let router: any CalendarFeatureRouting

    public init(
        userUuid: String = "demo-user",
        router: any CalendarFeatureRouting
    ) {
        self.userUuid = userUuid
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CalendarFeature")
                .font(.title.bold())
            Text("달력 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Button("알림 화면 열기") {
                router.route(to: .alert)
            }
            .buttonStyle(.bordered)
            Button("팝업 상세 열기") {
                router.route(to: .popupDetail(.popupMock))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
