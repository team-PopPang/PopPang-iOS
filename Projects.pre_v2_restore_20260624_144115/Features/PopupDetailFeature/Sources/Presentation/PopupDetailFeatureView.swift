import Domain
import PopupDetailFeatureInterface
import SwiftUI

public struct PopupDetailFeatureView: View {
    private let userUuid: String
    private let popup: Popup
    private let isAdmin: Bool
    private let hidesSystemTabBar: Bool
    private let router: any PopupDetailFeatureRouting

    public init(
        userUuid: String = "demo-user",
        popup: Popup = .popupMock,
        isAdmin: Bool = false,
        hidesSystemTabBar: Bool = true,
        router: any PopupDetailFeatureRouting
    ) {
        self.userUuid = userUuid
        self.popup = popup
        self.isAdmin = isAdmin
        self.hidesSystemTabBar = hidesSystemTabBar
        self.router = router
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("PopupDetailFeature")
                    .font(.title.bold())
                Text(popup.name)
                    .font(.headline)
                Text("관리자: \(isAdmin ? "yes" : "no"), 탭바 숨김: \(hidesSystemTabBar ? "yes" : "no")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("연관 팝업 열기") {
                    router.route(to: .popupDetail(.popupMock2))
                }
                .buttonStyle(.bordered)

                Button("리뷰 보기") {
                    router.route(to: .reviewDetail(Review.mock))
                }
                .buttonStyle(.bordered)

                Button("비활성화 완료 처리") {
                    router.route(to: .close)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}
