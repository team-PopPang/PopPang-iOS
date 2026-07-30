import ComposableArchitecture
import Domain
import Foundation
import PopupDetailFeature
import SwiftUI

@main
struct PopupDetailFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PopupDetailFeatureView(
                store: Store(
                    initialState: PopupDetailFeature.State(
                        userUuid: "demo-user",
                        popup: .popupDetailDemo
                    )
                ) {
                    PopupDetailFeature()
                } withDependencies: {
                    $0.popupDetailClient = PopupDetailClient(
                        increaseViewCount: { _ in },
                        getPersonalRelatedPopupList: { _, _ in
                            [.relatedPopupDetailDemo]
                        },
                        addFavorite: { _, _ in },
                        removeFavorite: { _, _ in },
                        deactivatePopup: { _, _ in }
                    )
                }
            )
        }
    }
}

private extension Popup {
    static let popupDetailDemo = Popup(
        popupUuid: "popup-detail-demo",
        name: "더현대 서울 x 도시크랩",
        startDate: .popupDetailDemoDate(year: 2026, month: 7, day: 24),
        endDate: .popupDetailDemoDate(year: 2026, month: 7, day: 31),
        openTime: "00:00",
        closeTime: "00:00",
        address: "서울 영등포구 여의도동",
        roadAddress: "서울 영등포구 여의대로 108 지하2층",
        region: "서울",
        latitude: 37.5259,
        longitude: 126.9284,
        instaPostId: nil,
        instaPostUrl: "https://www.instagram.com/",
        captionSummary: """
        🦀 더현대 서울 x 도시크랩 팝업
        📍 더현대 서울
        📅 7.24 ~ 7.31
        🕒 운영시간 미기재

        푸드 팝업으로 진행되는 행사입니다.
        게살 내장볶음밥과 칠리새우 세트 메뉴가 소개되어 있어요.
        넛츠그린 스파클링 음료도 함께 만나볼 수 있습니다.
        만원대 구성으로 가볍게 즐기기 좋습니다.
        짧은 기간 동안 열리는 만큼 현장 분위기도 빠르게 지나갈 것 같아요.
        맛있는 메뉴를 중심으로 구성된 캐주얼한 팝업입니다.
        """,
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_2.jpg",
        ],
        mediaType: .carousel,
        favoriteCount: 52,
        viewCount: 244,
        isFavorited: false,
        recommendList: ["디저트"]
    )

    static let relatedPopupDetailDemo = Popup(
        popupUuid: "related-popup-detail-demo",
        name: "여의도 디저트 팝업",
        startDate: .popupDetailDemoDate(year: 2026, month: 8, day: 1),
        endDate: .popupDetailDemoDate(year: 2026, month: 8, day: 7),
        openTime: "10:30",
        closeTime: "20:00",
        address: "서울 영등포구 여의도동",
        roadAddress: "서울 영등포구 여의대로 108",
        region: "서울",
        latitude: 37.5259,
        longitude: 126.9284,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "팝업 상세 화면의 추천 카드 확인을 위한 데모입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 18,
        viewCount: 96,
        isFavorited: true,
        recommendList: ["디저트"]
    )
}

private extension Date {
    static func popupDetailDemoDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        ) ?? .distantPast
    }
}
