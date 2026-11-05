import ComposableArchitecture
import Domain
import Foundation

/// 홈이 쓰는 서버 요청. 모두 V2라 Access Token의 사용자를 기준으로 하고 `userUuid`를 받지 않는다.
public struct HomePopupClient: Sendable {
    var getRegionList: @Sendable () async throws -> [RegionList]
    public var getRandomPopupList: @Sendable () async throws -> [Popup]
    var getUpcomingPopupList: @Sendable () async throws -> [Popup]
    var getFilteredPopupList: @Sendable (
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void
}

extension HomePopupClient {
    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        
        return Self(
            getRegionList: {
                try await popupUsecase.getRegionList()
            },
            getRandomPopupList: {
                try await popupUsecase.getUserRandomPopupList()
            },
            getUpcomingPopupList: {
                try await popupUsecase.getUserUpcomingPopupList()
            },
            getFilteredPopupList: { region, district, homeSortStandard in
                try await popupUsecase.getFilteredPopupList(
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { popupUuid in
                try await popupUsecase.addFavorite(popupUuid: popupUuid)
            },
            removeFavorite: { popupUuid in
                try await popupUsecase.removeFavorite(popupUuid: popupUuid)
            }
        )
    }
}

extension HomePopupClient: DependencyKey {
    public static let liveValue = HomePopupClient(
        getRegionList: { [] },
        getRandomPopupList: { [] },
        getUpcomingPopupList: { [] },
        getFilteredPopupList: { _, _, _ in [] },
        addFavorite: { _ in },
        removeFavorite: { _ in }
    )
    
#if DEBUG
    public static var previewValue: HomePopupClient {
        let now = Date()
        
        func makePopups(section: String) -> [Popup] {
            [
                .homeFeaturePreview(
                    popupUuid: "preview-\(section)-1",
                    name: "성수 라이프스타일 팝업",
                    roadAddress: "서울 성동구 성수동",
                    startDate: now.addingTimeInterval(60 * 60 * 24 * 2),
                    endDate: now.addingTimeInterval(60 * 60 * 24 * 12),
                    favoriteCount: 124,
                    viewCount: 851,
                    isFavorited: true,
                    recommendList: ["생활용품", "친환경"]
                ),
                .homeFeaturePreview(
                    popupUuid: "preview-\(section)-2",
                    name: "홍대 디저트 마켓",
                    roadAddress: "서울 마포구 서교동",
                    startDate: now.addingTimeInterval(60 * 60 * 24 * 5),
                    endDate: now.addingTimeInterval(60 * 60 * 24 * 15),
                    favoriteCount: 78,
                    viewCount: 430,
                    recommendList: ["디저트", "카페"]
                ),
                .homeFeaturePreview(
                    popupUuid: "preview-\(section)-3",
                    name: "더현대 패션 쇼룸",
                    roadAddress: "서울 영등포구 여의도동",
                    startDate: now.addingTimeInterval(-60 * 60 * 24),
                    endDate: now.addingTimeInterval(60 * 60 * 24 * 8),
                    favoriteCount: 210,
                    viewCount: 1_924,
                    recommendList: ["패션", "뷰티"]
                ),
                .homeFeaturePreview(
                    popupUuid: "preview-\(section)-4",
                    name: "잠실 캐릭터 굿즈 페어",
                    roadAddress: "서울 송파구 잠실동",
                    startDate: now.addingTimeInterval(60 * 60 * 24 * 9),
                    endDate: now.addingTimeInterval(60 * 60 * 24 * 20),
                    favoriteCount: 56,
                    viewCount: 619,
                    isFavorited: true,
                    recommendList: ["애니메이션", "게임"]
                ),
            ]
        }
        
        let bestPopups = makePopups(section: "best")
        let comingPopups = makePopups(section: "coming")
        let gridPopups = makePopups(section: "grid")
        
        return HomePopupClient(
            getRegionList: {
                [
                    RegionList(
                        region: "전체",
                        districtList: ["전체"]
                    ),
                    RegionList(
                        region: "서울",
                        districtList: [
                            "전체",
                            "성동구",
                            "마포구",
                            "영등포구",
                            "송파구",
                        ]
                    ),
                    RegionList(
                        region: "부산",
                        districtList: ["전체", "해운대구", "수영구"]
                    ),
                ]
            },
            getRandomPopupList: { bestPopups },
            getUpcomingPopupList: { comingPopups },
            getFilteredPopupList: { _, _, _ in gridPopups },
            addFavorite: { _ in
                print("previewValue: 팝업 좋아요 + 1")
            },
            removeFavorite: { _ in
                print("previewValue: 팝업 좋아요 - 1")
            }
        )
    }
#endif
}

#if DEBUG
private extension Popup {
    static func homeFeaturePreview(
        popupUuid: String,
        name: String,
        roadAddress: String,
        startDate: Date,
        endDate: Date,
        favoriteCount: Int,
        viewCount: Int,
        isFavorited: Bool = false,
        recommendList: [String]
    ) -> Popup {
        Popup(
            popupUuid: popupUuid,
            name: name,
            startDate: startDate,
            endDate: endDate,
            openTime: "10:00",
            closeTime: "20:00",
            address: roadAddress,
            roadAddress: roadAddress,
            region: "서울",
            latitude: 37.544,
            longitude: 127.055,
            instaPostId: nil,
            instaPostUrl: nil,
            captionSummary: "프리뷰용 팝업 소개 문구입니다.",
            imageUrlList: [
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
            ],
            mediaType: .image,
            favoriteCount: favoriteCount,
            viewCount: viewCount,
            isFavorited: isFavorited,
            recommendList: recommendList
        )
    }
}
#endif

extension HomePopupClient: TestDependencyKey {
    public static var testValue: HomePopupClient {
        HomePopupClient(
            getRegionList: { [] },
            getRandomPopupList: { [] },
            getUpcomingPopupList: { [] },
            getFilteredPopupList: { _, _, _ in [] },
            addFavorite: { _ in },
            removeFavorite: { _ in }
        )
    }
}

extension DependencyValues {
    public var homePopupClient: HomePopupClient {
        get { self[HomePopupClient.self] }
        set { self[HomePopupClient.self] = newValue }
    }
}
