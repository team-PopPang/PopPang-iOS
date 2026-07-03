import ComposableArchitecture
import Domain
import SearchFeature
import SwiftUI

@main
struct SearchFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            SearchFeatureView(
                store: Store(
                    initialState: SearchFeature.State(
                        userUuid: "demo-user",
                        nickname: "홍길동"
                    )
                ) {
                    SearchFeature()
                } withDependencies: {
                    $0.searchFeatureClient = SearchFeatureClient(
                        loadRecentKeywords: {
                            ["성수", "연남", "부산"]
                        },
                        addRecentKeyword: { _ in },
                        removeRecentKeyword: { _ in },
                        searchPopups: { _, searchText in
                            searchText.isEmpty ? [] : [.demo]
                        }
                    )
                }
            )
        }
    }
}

private extension Popup {
    static let demo = Popup(
        popupUuid: "search-demo",
        name: "성수 검색 팝업",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
        openTime: "10:00",
        closeTime: "20:00",
        address: "서울 성동구 성수동",
        roadAddress: "서울 성동구 성수동",
        region: "서울",
        latitude: 37.544,
        longitude: 127.055,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "검색 데모 팝업입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 12,
        viewCount: 84,
        isFavorited: false,
        recommendList: ["패션", "라이프스타일"]
    )
}
