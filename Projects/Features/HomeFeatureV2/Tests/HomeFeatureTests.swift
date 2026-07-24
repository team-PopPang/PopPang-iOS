import ComposableArchitecture
import Domain
import DSKit
import Foundation
import Testing
@testable import HomeFeatureV2

@MainActor
struct HomeFeatureTests {
    @Test("HomeFilterFeature가 서버에서 준비한 지역 선택 상태를 반영한다")
    func homeFilterAppliesPreparedRegionSelection() async {
        let seoul = RegionList(
            region: "서울",
            districtList: ["전체", "성동구", "마포구"]
        )
        let busan = RegionList(
            region: "부산",
            districtList: ["전체", "해운대구"]
        )
        let selection = HomeRegionSelection(
            regions: [seoul, busan],
            selectedRegion: seoul,
            selectedDistrict: "성동구"
        )

        let store = TestStore(initialState: HomeFilterFeature.State()) {
            HomeFilterFeature()
        }

        await store.send(.regionSelectionPrepared(selection)) {
            $0.regions = [seoul, busan]
            $0.selectedRegion = seoul
            $0.selectedDistrict = "성동구"
        }
    }

    @Test("HomeFeature가 onAppear 시 필터와 섹션 데이터를 함께 로드한다")
    func homeFeatureLoadsSectionsOnAppear() async {
        let user = makeUser()
        let seoul = RegionList(
            region: "서울",
            districtList: ["전체", "성동구"]
        )
        let busan = RegionList(
            region: "부산",
            districtList: ["전체", "해운대구"]
        )
        let bestPopups = [
            makePopup(popupUuid: "best-1", name: "베스트 팝업")
        ]
        let comingLater = makePopup(
            popupUuid: "coming-2",
            name: "나중 오픈 팝업",
            startDate: Date(timeIntervalSince1970: 1_718_236_800)
        )
        let comingSooner = makePopup(
            popupUuid: "coming-1",
            name: "먼저 오픈 팝업",
            startDate: Date(timeIntervalSince1970: 1_718_150_400)
        )
        let gridPopups = [
            makePopup(popupUuid: "grid-1", name: "그리드 팝업")
        ]

        let store = TestStore(
            initialState: HomeFeature.State(user: user)
        ) {
            HomeFeature()
        } withDependencies: {
            $0.homePopupClient.getRegionList = {
                [busan, seoul]
            }
            $0.homePopupClient.getPersonalRandomPopupList = { userUuid in
                #expect(userUuid == "user-1")
                return bestPopups
            }
            $0.homePopupClient.getPersonalUpcomingPopupList = { userUuid in
                #expect(userUuid == "user-1")
                return [comingLater, comingSooner]
            }
            $0.homePopupClient.getPersonalFilteredPopupList = {
                userUuid, selectedRegion, district, sort in
                #expect(userUuid == "user-1")
                #expect(selectedRegion == "서울")
                #expect(district == "전체")
                #expect(sort == SortButton.SortOption.newest.rawValue)
                return gridPopups
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(
            .filter(
                .regionSelectionPrepared(
                    HomeRegionSelection(
                        regions: [seoul, busan],
                        selectedRegion: seoul,
                        selectedDistrict: "전체"
                    )
                )
            )
        ) {
            $0.filter.regions = [seoul, busan]
            $0.filter.selectedRegion = seoul
            $0.filter.selectedDistrict = "전체"
        }

        await store.receive(
            .popupSectionsLoaded(
                HomePopupSections(
                    bestPopups: bestPopups,
                    comingPopups: [comingLater, comingSooner],
                    gridPopups: gridPopups
                )
            )
        ) {
            $0.bestPopups = bestPopups
            $0.comingPopups = [comingSooner, comingLater]
            $0.gridPopups = gridPopups
            $0.errorMessage = nil
        }

        await store.receive(.loadingChanged(false)) {
            $0.isLoading = false
        }
    }

    @Test("HomeFeature가 refreshFilteredPopupList 시 현재 필터로 목록을 다시 조회한다")
    func homeFeatureRefreshesFilteredList() async {
        let region = RegionList(
            region: "서울",
            districtList: ["전체", "성동구"]
        )
        let expectedPopups = [
            makePopup(popupUuid: "popup-1", name: "성수 팝업")
        ]
        var initialState = HomeFeature.State(user: makeUser())
        initialState.filter.selectedRegion = region
        initialState.filter.selectedDistrict = "성동구"
        initialState.filter.selectedOption = .mostFavorited

        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.homePopupClient.getPersonalFilteredPopupList = {
                userUuid, selectedRegion, district, sort in
                #expect(userUuid == "user-1")
                #expect(selectedRegion == "서울")
                #expect(district == "성동구")
                #expect(sort == SortButton.SortOption.mostFavorited.rawValue)
                return expectedPopups
            }
        }

        await store.send(.refreshFilteredPopupList) {
            $0.isLoading = true
        }

        await store.receive(.filteredGridPopupList(expectedPopups)) {
            $0.gridPopups = expectedPopups
            $0.errorMessage = nil
        }

        await store.receive(.loadingChanged(false)) {
            $0.isLoading = false
        }
    }

    @Test("HomeFeature는 favoriteUpdateResponse를 모든 섹션에 반영한다")
    func homeFeatureAppliesFavoriteUpdateAcrossSections() async {
        let popup = makePopup(
            popupUuid: "popup-1",
            name: "성수 팝업",
            favoriteCount: 1,
            isFavorited: false
        )
        var initialState = HomeFeature.State(user: makeUser())
        initialState.bestPopups = [popup]
        initialState.comingPopups = [popup]
        initialState.gridPopups = [popup]

        let store = TestStore(initialState: initialState) {
            HomeFeature()
        }

        await store.send(
            .favoriteUpdateResponse(
                popupUuid: "popup-1",
                isFavorited: true,
                favoriteCount: 2
            )
        ) {
            $0.bestPopups[0].isFavorited = true
            $0.bestPopups[0].favoriteCount = 2
            $0.comingPopups[0].isFavorited = true
            $0.comingPopups[0].favoriteCount = 2
            $0.gridPopups[0].isFavorited = true
            $0.gridPopups[0].favoriteCount = 2
        }
    }

    @Test("HomeFeature는 popupSelected를 delegate로 전달한다")
    func homeFeatureForwardsPopupSelectionDelegate() async {
        let popup = makePopup(popupUuid: "popup-1", name: "성수 팝업")
        let store = TestStore(initialState: HomeFeature.State(user: makeUser())) {
            HomeFeature()
        }

        await store.send(.popupSelected(popup))
        await store.receive(.delegate(.popupSelected(popup)))
    }

    @Test("ComingPopupDetailFeature가 좋아요 요청 실패 시 optimistic update를 되돌린다")
    func comingPopupDetailFeatureRollsBackFavoriteWhenRequestFails() async {
        let popup = makePopup(
            popupUuid: "popup-1",
            name: "성수 팝업",
            favoriteCount: 3,
            isFavorited: false
        )

        let store = TestStore(
            initialState: ComingPopupDetailFeature.State(
                userUuid: "user-1",
                popups: [popup]
            )
        ) {
            ComingPopupDetailFeature()
        } withDependencies: {
            $0.homePopupClient.addFavorite = { _, _ in
                throw TestError.expectedFailure
            }
        }

        await store.send(.toggleLike(popup)) {
            $0.popups[0].isFavorited = true
            $0.popups[0].favoriteCount = 4
        }

        await store.receive(
            .favoriteUpdated(
                popupUuid: "popup-1",
                isFavorited: false,
                favoriteCount: 3
            )
        ) {
            $0.popups[0].isFavorited = false
            $0.popups[0].favoriteCount = 3
        }

        await store.receive(
            .errorMessageChanged(TestError.expectedFailure.localizedDescription)
        ) {
            $0.isLoading = false
            $0.errorMessage = TestError.expectedFailure.localizedDescription
        }
    }
}

private enum TestError: LocalizedError {
    case expectedFailure

    var errorDescription: String? {
        switch self {
        case .expectedFailure:
            "expected failure"
        }
    }
}

private func makeUser() -> User {
    User(
        userUuid: "user-1",
        uid: "test-uid",
        provider: "test",
        email: nil,
        nickname: "팝팡",
        role: "USER",
        isAlerted: false,
        fcmToken: nil,
        alertKeywordList: nil,
        recommendList: nil
    )
}

private func makePopup(
    popupUuid: String,
    name: String,
    favoriteCount: Int = 0,
    isFavorited: Bool = false,
    startDate: Date = Date(timeIntervalSince1970: 1_718_150_400)
) -> Popup {
    Popup(
        popupUuid: popupUuid,
        name: name,
        startDate: startDate,
        endDate: Date(timeIntervalSince1970: 1_718_236_800),
        openTime: "10:00",
        closeTime: "20:00",
        address: "서울 성동구 성수동",
        roadAddress: "서울 성동구 성수이로",
        region: "서울",
        latitude: 37.544,
        longitude: 127.055,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "테스트용 팝업",
        imageUrlList: [],
        mediaType: .image,
        favoriteCount: favoriteCount,
        viewCount: 10,
        isFavorited: isFavorited,
        recommendList: ["테스트"]
    )
}
