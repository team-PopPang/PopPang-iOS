import Domain
import AlertFeatureInterface
import SwiftUI

public struct AlertFeatureView: View {
    private let userUuid: String
    private let nickname: String
    private let router: any AlertFeatureRouting

    public init(
        userUuid: String = "demo-user",
        nickname: String = "홍길동",
        router: any AlertFeatureRouting
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.router = router
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AlertFeature")
                    .font(.title.bold())
                Text("\(nickname)님의 알림 화면은 코디네이터 재구성 전 임시 placeholder 상태입니다.")
                    .foregroundStyle(.secondary)
                Button("팝업 상세 임시 이동") {
                    router.route(to: .popupDetail(.popupMock))
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}
