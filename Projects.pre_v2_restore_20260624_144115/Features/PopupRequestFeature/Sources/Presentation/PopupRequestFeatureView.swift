import PopupRequestFeatureInterface
import SwiftUI

public struct PopupRequestFeatureView: View {
    private let userUuid: String
    private let router: any PopupRequestFeatureRouting

    public init(
        userUuid: String = "demo-user",
        router: any PopupRequestFeatureRouting
    ) {
        self.userUuid = userUuid
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PopupRequestFeature")
                .font(.title.bold())
            Text("제보 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Text("userUuid: \(userUuid)")
                .font(.subheadline)
            Button("닫기") {
                router.route(to: .close)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
