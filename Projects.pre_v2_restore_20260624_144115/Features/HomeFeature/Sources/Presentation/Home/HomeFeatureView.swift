import ADKit
import Core
import Domain
import HomeFeatureInterface
import SwiftUI

public struct HomeFeatureView: View {
    private let userUuid: String
    private let nickname: String
    private let isAdmin: Bool
    private let router: any HomeFeatureRouting

    public init(
        userUuid: String = "demo-user",
        nickname: String = "닉네임",
        isAdmin: Bool = false,
        router: any HomeFeatureRouting,
        nativeAdPlacementConfiguration: AdNativeAdPlacementConfiguration = .homeGrid,
        nativeAdCount: Int? = nil,
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore())
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAdmin = isAdmin
        self.router = router
        _ = nativeAdPlacementConfiguration
        _ = nativeAdCount
        _ = deepLinkStorage
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("HomeFeature")
                    .font(.title.bold())
                Text("\(nickname)님의 홈 화면은 임시 placeholder 상태입니다.")
                    .foregroundStyle(.secondary)
                Text("관리자 여부: \(isAdmin ? "admin" : "user")")
                    .font(.subheadline)

                Button("팝업 상세 열기") {
                    router.route(to: .popupDetail(.popupMock))
                }
                .buttonStyle(.borderedProminent)

                Button("알림 화면 열기") {
                    router.route(to: .alert)
                }
                .buttonStyle(.bordered)

                Button("검색 전체화면 열기") {
                    router.route(to: .search)
                }
                .buttonStyle(.bordered)

                Button("오픈 예정 목록 열기") {
                    router.route(to: .comingPopupDetail([.popupMock, .popupMock2]))
                }
                .buttonStyle(.bordered)

                Button("제보 화면 열기") {
                    router.route(to: .popupRequest)
                }
                .buttonStyle(.bordered)

                Button("제보 관리 화면 열기") {
                    router.route(to: .popupRequestManagement)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}
