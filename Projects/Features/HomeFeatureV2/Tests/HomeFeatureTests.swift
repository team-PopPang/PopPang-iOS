import ADKit
import ComposableArchitecture
import Core
import Domain
import DSKit
import Foundation
import Testing
@testable import HomeFeatureV2

@MainActor
struct HomeFeatureTests {
    @Test("V2 paginated Home grid policy preserves V1 slots and extends after the third ad")
    func paginatedHomeGridPolicyPreservesAndExtendsSlots() {
        let userIdentifier = "user-1"
        let date = Date(timeIntervalSince1970: 1_720_000_000)

        let noPlacements = AdNativeAdPlacementPolicy.paginatedHomeGridPlacements(
            contentCount: 7,
            userIdentifier: userIdentifier,
            date: date
        )
        #expect(noPlacements.isEmpty)

        for contentCount in [8, 20, 32] {
            let paginatedPlacements = AdNativeAdPlacementPolicy.paginatedHomeGridPlacements(
                contentCount: contentCount,
                userIdentifier: userIdentifier,
                date: date
            )
            let v1Placements = AdNativeAdPlacementPolicy.placements(
                contentCount: contentCount,
                userIdentifier: userIdentifier,
                date: date,
                configuration: .homeGrid
            )

            #expect(paginatedPlacements == v1Placements)
        }

        let placementsAt20 = AdNativeAdPlacementPolicy.paginatedHomeGridPlacements(
            contentCount: 20,
            userIdentifier: userIdentifier,
            date: date
        )

        #expect(placementsAt20.map(\.id) == ["native-ad-1", "native-ad-2"])
        #expect([4, 6].contains(placementsAt20[0].insertIndex))
        #expect([14, 16].contains(placementsAt20[1].insertIndex))

        let placementsAt44 = AdNativeAdPlacementPolicy.paginatedHomeGridPlacements(
            contentCount: 44,
            userIdentifier: userIdentifier,
            date: date
        )

        #expect(placementsAt44.map(\.id) == [
            "native-ad-1",
            "native-ad-2",
            "native-ad-3",
            "native-ad-4",
        ])
        #expect(Array(placementsAt44.prefix(2)) == placementsAt20)
        #expect([24, 26].contains(placementsAt44[2].insertIndex))
        #expect([34, 36].contains(placementsAt44[3].insertIndex))
    }

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
            $0.homePopupClient.getRandomPopupList = {
                bestPopups
            }
            $0.homePopupClient.getUpcomingPopupList = {
                [comingLater, comingSooner]
            }
            $0.homePopupClient.getFilteredPopupList = {
                selectedRegion, district, sort in
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

    @Test("HomeFeature가 닉네임 갱신 action을 상태에 반영한다")
    func homeFeatureUpdatesNickname() async {
        let store = TestStore(initialState: HomeFeature.State(user: makeUser())) {
            HomeFeature()
        }

        await store.send(.nicknameUpdated("새 팝팡")) {
            $0.nickname = "새 팝팡"
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
            $0.homePopupClient.getFilteredPopupList = {
                selectedRegion, district, sort in
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
            $0.homePopupClient.addFavorite = { _ in
                throw TestError.expectedFailure
            }
        }

        await store.send(.toggleLike(popup)) {
            $0.favoriteInFlight = ["popup-1"]
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
            .errorMessageChanged(ComingPopupDetailFeature.favoriteFailedMessage)
        ) {
            $0.isLoading = false
            $0.errorMessage = ComingPopupDetailFeature.favoriteFailedMessage
        }

        await store.receive(.favoriteRequestFinished(popupUuid: "popup-1")) {
            $0.favoriteInFlight = []
        }
    }

    @Test("HomeFeature는 찜 응답을 기다리는 동안 같은 하트를 다시 누르면 요청을 다시 보내지 않는다")
    func homeFeatureIgnoresFavoriteTapWhileInFlight() async {
        let clock = TestClock()
        let calls = LockIsolated<[String]>([])
        let popup = makePopup(popupUuid: "popup-1", name: "성수 팝업", favoriteCount: 3)
        var initialState = HomeFeature.State(user: makeUser())
        initialState.gridPopups = [popup]

        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.homePopupClient.addFavorite = { uuid in
                calls.withValue { $0.append("add:\(uuid)") }
                try await clock.sleep(for: .seconds(1))
            }
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.favoriteToggleTapped(popupUuid: "popup-1"))
        await store.send(.favoriteToggleTapped(popupUuid: "popup-1"))
        await clock.advance(by: .seconds(1))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(calls.value == ["add:popup-1"])
        #expect(store.state.gridPopups.first?.favoriteCount == 4)
        #expect(store.state.favoriteInFlight.isEmpty)
    }

    @Test("HomeFeature는 그리드를 빠르게 다시 불러오면 마지막 요청의 응답만 반영한다")
    func homeFeatureKeepsOnlyLatestGridResponse() async {
        let clock = TestClock()
        let callCount = LockIsolated(0)
        let store = TestStore(initialState: HomeFeature.State(user: makeUser())) {
            HomeFeature()
        } withDependencies: {
            $0.homePopupClient.getFilteredPopupList = { _, _, _ in
                let call = callCount.withValue { count -> Int in
                    count += 1
                    return count
                }
                // 첫 요청은 늦게 끝나게 한다.
                if call == 1 {
                    try await clock.sleep(for: .seconds(5))
                    return [makePopup(popupUuid: "old", name: "이전 응답")]
                }
                return [makePopup(popupUuid: "new", name: "최신 응답")]
            }
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.refreshFilteredPopupList)
        await store.send(.refreshFilteredPopupList)
        await clock.advance(by: .seconds(5))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.gridPopups.map(\.popupUuid) == ["new"])
        #expect(store.state.isLoading == false)
    }

    @Test("ComingPopupDetailFeature는 목록을 불러오지 못하면 안내 문구를, 로그인이 끊기면 문구 없이 둔다")
    func comingPopupDetailFeatureLoadFailureMessages() async {
        let failing = TestStore(
            initialState: ComingPopupDetailFeature.State(userUuid: "user-1", popups: [])
        ) {
            ComingPopupDetailFeature()
        } withDependencies: {
            $0.homePopupClient.getUpcomingPopupList = { throw PopupError.failed }
        }
        failing.exhaustivity = .off(showSkippedAssertions: false)
        await failing.send(.onAppear)
        await failing.finish()
        await failing.skipReceivedActions(strict: false)
        #expect(failing.state.errorMessage == ComingPopupDetailFeature.loadFailedMessage)
        #expect(failing.state.isLoading == false)

        let loggedOut = TestStore(
            initialState: ComingPopupDetailFeature.State(userUuid: "user-1", popups: [])
        ) {
            ComingPopupDetailFeature()
        } withDependencies: {
            $0.homePopupClient.getUpcomingPopupList = { throw AuthSessionError.loginRequired }
        }
        loggedOut.exhaustivity = .off(showSkippedAssertions: false)
        await loggedOut.send(.onAppear)
        await loggedOut.finish()
        await loggedOut.skipReceivedActions(strict: false)
        #expect(loggedOut.state.errorMessage == nil)
        #expect(loggedOut.state.isLoading == false)
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
        provider: nil,
        email: nil,
        nickname: "팝팡",
        role: .member,
        isAlerted: false
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
