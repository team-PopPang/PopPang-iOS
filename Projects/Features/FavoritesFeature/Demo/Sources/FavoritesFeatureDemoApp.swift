import ComposableArchitecture
import Domain
import FavoritesFeature
import SwiftUI

@main
struct FavoritesFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            FavoritesFeatureView(
                store: Store(
                    initialState: FavoritesFeature.State(
                        userUuid: User.demo.userUuid
                    )
                ) {
                    FavoritesFeature()
                } withDependencies: {
                    $0.favoritesFeatureClient = FavoritesFeatureClient(
                        getFavoriteList: { _ in
                            [.demo]
                        },
                        addFavorite: { _, _ in },
                        removeFavorite: { _, _ in }
                    )
                }
            )
        }
    }
}

private extension User {
    static let demo = User(
        userUuid: "demo-user",
        uid: "demo-user",
        provider: "KAKAO",
        email: nil,
        nickname: "홍길동",
        role: "USER",
        isAlerted: false,
        fcmToken: nil,
        alertKeywordList: nil,
        recommendList: nil
    )
}

private extension Popup {
    static let demo = Popup(
        popupUuid: "favorite-demo",
        name: "성수 찜 팝업",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        openTime: "10:00",
        closeTime: "20:00",
        address: "서울 성동구 성수동",
        roadAddress: "서울 성동구 성수동",
        region: "서울",
        latitude: 37.544,
        longitude: 127.055,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "데모 찜 팝업입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 24,
        viewCount: 128,
        isFavorited: true,
        recommendList: ["패션", "라이프스타일"]
    )
}
