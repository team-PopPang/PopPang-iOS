import ComposableArchitecture
import Domain
import MapFeature
import SwiftUI

@main
struct MapFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            MapFeatureView(
                store: Store(
                    initialState: MapFeature.State(
                        userUuid: User.demo.userUuid
                    )
                ) {
                    MapFeature()
                } withDependencies: {
                    $0.mapFeatureClient = MapFeatureClient(
                        getRegionList: {
                            [
                                RegionList(region: "전체", districtList: ["전체"]),
                                RegionList(region: "서울", districtList: ["전체", "성동구", "마포구"]),
                            ]
                        },
                        getPopularRecommendList: {
                            [
                                Recommend(id: 1, recommendName: "패션"),
                                Recommend(id: 2, recommendName: "라이프스타일"),
                            ]
                        },
                        getPopularRecommendPopupList: { _, recommendId in
                            recommendId == 1 ? [.demo] : [.secondaryDemo]
                        },
                        getPersonalMapFilteredPopupList: { _, _, _, _, _, _ in
                            [.demo, .secondaryDemo]
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
        popupUuid: "map-demo",
        name: "성수 지도 팝업",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        openTime: "10:00",
        closeTime: "20:00",
        address: "서울 성동구 성수동",
        roadAddress: "서울 성동구 성수동",
        region: "서울",
        latitude: 37.544,
        longitude: 127.055,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "지도 데모 팝업입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 12,
        viewCount: 84,
        isFavorited: false,
        recommendList: ["패션", "라이프스타일"]
    )

    static let secondaryDemo = Popup(
        popupUuid: "map-demo-2",
        name: "연남 지도 팝업",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        openTime: "11:00",
        closeTime: "21:00",
        address: "서울 마포구 연남동",
        roadAddress: "서울 마포구 연남동",
        region: "서울",
        latitude: 37.561,
        longitude: 126.923,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "지도 데모 팝업 2입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 8,
        viewCount: 42,
        isFavorited: true,
        recommendList: ["라이프스타일"]
    )
}
