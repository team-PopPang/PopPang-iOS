import ComposableArchitecture
import Domain
import DSKit
import Foundation
import Testing
@testable import HomeFeature

@MainActor
struct HomeFeatureReducerTests {
    @Test("HomeFilterReducer가 지역 선택 시 첫 번째 구를 기본값으로 설정한다")
    func homeFilterReducerSelectsFirstDistrictWhenRegionChanges() async {
        let region = RegionList(region: "서울", districtList: ["전체", "성동구", "마포구"])
        let store = TestStore(initialState: HomeFilterReducer.State()) {
            HomeFilterReducer()
        }

        await store.send(.regionSelected(region)) {
            $0.selectedRegion = region
            $0.selectedDistrict = "전체"
        }
    }

    @Test("HomeFeatureReducer가 정렬 변경 시 필터 목록 재조회 effect를 시작한다")
    func homeFeatureReducerReloadsFilteredListWhenSortChanges() async {
        let region = RegionList(region: "서울", districtList: ["전체", "성동구"])
        let expectedPopups = [makePopup(popupUuid: "popup-1", name: "성수 팝업")]
        var initialState = HomeFeatureReducer.State(
            userUuid: "user-1",
            nickname: "팝팡",
            isAdmin: false
        )
        initialState.filter.selectedRegion = region
        initialState.filter.selectedDistrict = "전체"

        let store = TestStore(
            initialState: initialState
        ) {
            HomeFeatureReducer()
        } withDependencies: {
            $0.homePopupClient.getPersonalFilteredPopupList = { userUuid, selectedRegion, district, sort in
                #expect(userUuid == "user-1")
                #expect(selectedRegion == "서울")
                #expect(district == "전체")
                #expect(sort == SortButton.SortOption.mostFavorited.rawValue)
                return expectedPopups
            }
        }

        store.exhaustivity = .off

        await store.send(.filter(.sortOptionSelected(.mostFavorited))) {
            $0.filter.selectedOption = .mostFavorited
            $0.isLoading = true
        }

        await store.receive(.filteredPopupListLoaded(expectedPopups)) {
            $0.gridPopups = expectedPopups
            $0.errorMessage = nil
        }

        await store.receive(.loadingChanged(false)) {
            $0.isLoading = false
        }
    }

    @Test("ComingPopupDetailReducer가 좋아요 요청 실패 시 optimistic update를 되돌린다")
    func comingPopupDetailReducerRollsBackFavoriteWhenRequestFails() async {
        let popup = makePopup(
            popupUuid: "popup-1",
            name: "성수 팝업",
            favoriteCount: 3,
            isFavorited: false
        )

        let store = TestStore(
            initialState: ComingPopupDetailReducer.State(
                userUuid: "user-1",
                popups: [popup]
            )
        ) {
            ComingPopupDetailReducer()
        } withDependencies: {
            $0.homePopupClient.addFavorite = { _, _ in
                throw TestError.expectedFailure
            }
        }

        await store.send(.toggleLike(popup)) {
            $0.popups[0].isFavorited = true
            $0.popups[0].favoriteCount = 4
        }

        await store.receive(.favoriteUpdated(
            popupUuid: "popup-1",
            isFavorited: false,
            favoriteCount: 3
        )) {
            $0.popups[0].isFavorited = false
            $0.popups[0].favoriteCount = 3
        }

        await store.receive(.errorMessageChanged(TestError.expectedFailure.localizedDescription)) {
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

private func makePopup(
    popupUuid: String,
    name: String,
    favoriteCount: Int = 0,
    isFavorited: Bool = false
) -> Popup {
    Popup(
        popupUuid: popupUuid,
        name: name,
        startDate: Date(timeIntervalSince1970: 1_718_150_400),
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
