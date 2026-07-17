import ComposableArchitecture
import Domain
import Foundation

public struct HomePopupClient: Sendable {
    var getRegionList: @Sendable () async throws -> [RegionList]
    public var getPersonalRandomPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalUpcomingPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalFilteredPopupList: @Sendable (
        _ userUuid: String,
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
}

extension HomePopupClient {
    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let box = PopupUsecaseBox(popupUsecase)

        return Self(
            getRegionList: {
                try await box.usecase.getRegionList()
            },
            getPersonalRandomPopupList: { userUuid in
                try await box.usecase.getPersonalRandomPopupList(userUuid: userUuid)
            },
            getPersonalUpcomingPopupList: { userUuid in
                try await box.usecase.getPersonalUpcomingPopupList(userUuid: userUuid)
            },
            getPersonalFilteredPopupList: { userUuid, region, district, homeSortStandard in
                try await box.usecase.getPersonalFilteredPopupList(
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await box.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await box.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension HomePopupClient: DependencyKey {
    public static let liveValue = HomePopupClient(
        getRegionList: { [] },
        getPersonalRandomPopupList: { _ in [] },
        getPersonalUpcomingPopupList: { _ in [] },
        getPersonalFilteredPopupList: { _, _, _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
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
        getPersonalRandomPopupList: { _ in bestPopups },
        getPersonalUpcomingPopupList: { _ in comingPopups },
        getPersonalFilteredPopupList: { _, _, _, _ in gridPopups },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
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
            getPersonalRandomPopupList: { _ in [] },
            getPersonalUpcomingPopupList: { _ in [] },
            getPersonalFilteredPopupList: { _, _, _, _ in [] },
            addFavorite: { _, _ in },
            removeFavorite: { _, _ in }
        )
    }
}

extension DependencyValues {
    public var homePopupClient: HomePopupClient {
        get { self[HomePopupClient.self] }
        set { self[HomePopupClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}

