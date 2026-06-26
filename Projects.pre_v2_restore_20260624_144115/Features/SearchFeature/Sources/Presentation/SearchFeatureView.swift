import Core
import Domain
import SearchFeatureInterface
import SwiftUI

public struct SearchFeatureView: View {
    private let userUuid: String
    private let nickname: String
    private let router: any SearchFeatureRouting

    public init(
        userUuid: String = "demo-user",
        nickname: String = "홍길동",
        router: any SearchFeatureRouting,
        recentSearchStorage: RecentSearchStorage = RecentSearchStorage(store: UserDefaultsStore())
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.router = router
        _ = recentSearchStorage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SearchFeature")
                .font(.title.bold())
            Text("\(nickname)님 검색 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Text("userUuid: \(userUuid)")
                .font(.subheadline)
            Button("팝업 선택") {
                router.route(to: .selectPopup(.popupMock))
            }
            .buttonStyle(.borderedProminent)
            Button("닫기") {
                router.route(to: .close)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
