import ComposableArchitecture
import Core
import Domain
import Foundation
import Testing
@testable import CalendarFeatureV2

@MainActor
struct CalendarFeatureTests {
    @Test("처음 열면 지역 목록을 받아 전체·서울 순으로 두고, 첫 지역·구와 최신순으로 팝업을 불러온다")
    func onAppearLoadsRegionsAndPopups() async {
        let requests = LockIsolated<[FilterRequest]>([])
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getRegionList: { [.busan, .seoul, .all] },
                getFilteredPopupList: { region, district, sort in
                    requests.withValue { $0.append(.init(region: region, district: district, sort: sort)) }
                    return [.fixture()]
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.regions.map(\.region) == ["전체", "서울", "부산"])
        #expect(store.state.selectedRegion == .all)
        #expect(store.state.selectedDistrict == "전체")
        #expect(store.state.calendarPopups == [.fixture()])
        #expect(store.state.selectedPopups == [.fixture()])
        #expect(store.state.isLoading == false)
        #expect(requests.value == [.init(region: "전체", district: "전체", sort: "NEWEST")])
    }

    @Test("구를 고르면 고른 지역·구와 지금 정렬로 다시 불러온다")
    func districtSelectedReloadsWithSelection() async {
        let requests = LockIsolated<[FilterRequest]>([])
        var state = CalendarFeature.State()
        state.selectedRegion = .seoul
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getFilteredPopupList: { region, district, sort in
                    requests.withValue { $0.append(.init(region: region, district: district, sort: sort)) }
                    return []
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.districtSelected("성동구"))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.selectedDistrict == "성동구")
        #expect(store.state.isLoading == false)
        #expect(requests.value == [.init(region: "서울", district: "성동구", sort: "NEWEST")])
    }

    @Test("정렬을 바꾸면 지금 지역·구와 바꾼 정렬로 다시 불러온다")
    func sortOptionSelectedReloadsWithSort() async {
        let requests = LockIsolated<[FilterRequest]>([])
        var state = CalendarFeature.State()
        state.selectedRegion = .seoul
        state.selectedDistrict = "마포구"
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getFilteredPopupList: { region, district, sort in
                    requests.withValue { $0.append(.init(region: region, district: district, sort: sort)) }
                    return []
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.sortOptionSelected(.closingSoon))
        await store.finish()

        #expect(requests.value == [.init(region: "서울", district: "마포구", sort: "CLOSING_SOON")])
    }

    @Test("찜하지 않은 팝업의 하트를 누르면 popupUuid로 찜하고 개수를 하나 늘린다")
    func toggleLikeAddsFavorite() async {
        let calls = LockIsolated<[String]>([])
        let popup = Popup.fixture(isFavorited: false, favoriteCount: 3)
        var state = CalendarFeature.State()
        state.calendarPopups = [popup]
        state.selectedPopups = [popup]
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                addFavorite: { uuid in calls.withValue { $0.append("add:\(uuid)") } },
                removeFavorite: { uuid in calls.withValue { $0.append("remove:\(uuid)") } }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.toggleLike(popup))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(calls.value == ["add:popup-1"])
        #expect(store.state.calendarPopups.first?.isFavorited == true)
        #expect(store.state.calendarPopups.first?.favoriteCount == 4)
        #expect(store.state.selectedPopups.first?.favoriteCount == 4)
    }

    @Test("찜한 팝업의 하트를 누르면 popupUuid로 찜을 해제하고 개수를 하나 줄인다")
    func toggleLikeRemovesFavorite() async {
        let calls = LockIsolated<[String]>([])
        let popup = Popup.fixture(isFavorited: true, favoriteCount: 3)
        var state = CalendarFeature.State()
        state.calendarPopups = [popup]
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                addFavorite: { uuid in calls.withValue { $0.append("add:\(uuid)") } },
                removeFavorite: { uuid in calls.withValue { $0.append("remove:\(uuid)") } }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.toggleLike(popup))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(calls.value == ["remove:popup-1"])
        #expect(store.state.calendarPopups.first?.isFavorited == false)
        #expect(store.state.calendarPopups.first?.favoriteCount == 2)
    }

    @Test("불러오기가 실패하면 오류 문구를 채우고 로딩을 끈다")
    func loadFailureSetsErrorMessage() async {
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getRegionList: { [.all] },
                getFilteredPopupList: { _, _, _ in throw PopupError.failed }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.errorMessage == CalendarFeature.loadFailedMessage)
        #expect(store.state.isLoading == false)
        #expect(store.state.calendarPopups.isEmpty)
    }

    @Test("로그인이 끊긴 실패는 오류 문구를 띄우지 않는다")
    func loginRequiredShowsNoMessage() async {
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getRegionList: { [.all] },
                getFilteredPopupList: { _, _, _ in throw AuthSessionError.loginRequired }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.errorMessage == nil)
        #expect(store.state.isLoading == false)
    }

    @Test("찜 변경이 실패하면 찜 상태를 두고 안내 문구를 띄운다")
    func toggleLikeFailureShowsMessage() async {
        let popup = Popup.fixture(isFavorited: false, favoriteCount: 3)
        var state = CalendarFeature.State()
        state.calendarPopups = [popup]
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(addFavorite: { _ in throw PopupError.failed })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.toggleLike(popup))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.errorMessage == CalendarFeature.favoriteFailedMessage)
        #expect(store.state.calendarPopups.first?.isFavorited == false)
        #expect(store.state.calendarPopups.first?.favoriteCount == 3)
    }

    @Test("필터를 빠르게 바꾸면 앞 요청을 취소하고 마지막 조건의 응답만 반영한다")
    func newerFilterCancelsOlderRequest() async {
        let clock = TestClock()
        var state = CalendarFeature.State()
        state.selectedRegion = .seoul
        state.selectedDistrict = "전체"
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getFilteredPopupList: { _, _, sort in
                    // 앞 요청(최신순)은 뒤 요청(마감임박)보다 늦게 끝나게 한다.
                    if sort == "NEWEST" {
                        try await clock.sleep(for: .seconds(5))
                        return [.fixture(isFavorited: false, favoriteCount: 1)]
                    }
                    return [.fixture(isFavorited: false, favoriteCount: 2)]
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.districtSelected("성동구"))
        await store.send(.sortOptionSelected(.closingSoon))
        await clock.advance(by: .seconds(5))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        // 늦게 끝난 최신순 응답(찜 1개)이 마감임박 응답(찜 2개)을 덮어쓰지 않아야 한다.
        #expect(store.state.calendarPopups.map(\.favoriteCount) == [2])
        #expect(store.state.isLoading == false)
    }
}

extension CalendarFeatureTests {
    @Test("불러오는 중에 지역을 고르면 늦게 온 응답이 고른 지역을 덮어쓰지 않는다")
    func regionSelectedDuringLoadKeepsSelection() async {
        let clock = TestClock()
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getRegionList: { [.all, .seoul] },
                getFilteredPopupList: { _, _, _ in
                    try await clock.sleep(for: .seconds(5))
                    return [.fixture()]
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.send(.regionSelected(.seoul))
        await clock.advance(by: .seconds(5))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.selectedRegion == .seoul)
        #expect(store.state.selectedDistrict == "전체")
        #expect(store.state.isLoading == false)
    }
}

extension CalendarFeatureTests {
    @Test("지역을 받는 중에 정렬을 바꿔도 지역 목록을 받고, 팝업은 바꾼 정렬로 받는다")
    func sortChangeDuringRegionLoadKeepsRegions() async {
        let clock = TestClock()
        let requests = LockIsolated<[FilterRequest]>([])
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarFeatureClient = .mock(
                getRegionList: {
                    try await clock.sleep(for: .seconds(5))
                    return [.all, .seoul]
                },
                getFilteredPopupList: { region, district, sort in
                    requests.withValue { $0.append(.init(region: region, district: district, sort: sort)) }
                    return []
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.send(.sortOptionSelected(.closingSoon))
        await clock.advance(by: .seconds(5))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.regions.map(\.region) == ["전체", "서울"])
        #expect(store.state.selectedRegion == .all)
        #expect(requests.value.last == .init(region: "전체", district: "전체", sort: "CLOSING_SOON"))
        #expect(store.state.isLoading == false)
    }
}

private struct FilterRequest: Equatable, Sendable {
    let region: String
    let district: String
    let sort: String
}

private extension CalendarFeatureClient {
    static func mock(
        getRegionList: @escaping @Sendable () async throws -> [RegionList] = { [] },
        getFilteredPopupList: @escaping @Sendable (String, String, String) async throws -> [Popup] = { _, _, _ in [] },
        addFavorite: @escaping @Sendable (String) async throws -> Void = { _ in },
        removeFavorite: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> Self {
        Self(
            getRegionList: getRegionList,
            getFilteredPopupList: getFilteredPopupList,
            addFavorite: addFavorite,
            removeFavorite: removeFavorite
        )
    }
}

private extension RegionList {
    static let all = RegionList(region: "전체", districtList: ["전체"])
    static let seoul = RegionList(region: "서울", districtList: ["전체", "성동구", "마포구"])
    static let busan = RegionList(region: "부산", districtList: ["전체", "해운대구"])
}

private extension Popup {
    /// 오늘 시작해 사흘 뒤 끝나는 팝업. 날짜는 하루 단위로만 비교하므로 테스트 중 날짜가 바뀌지 않는 한 오늘 목록에 들어간다.
    static func fixture(isFavorited: Bool = false, favoriteCount: Int = 0) -> Popup {
        let start = Calendar.current.startOfDay(for: Date())
        return Popup(
            popupUuid: "popup-1",
            name: "성수 팝업",
            startDate: start,
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: start) ?? start,
            openTime: "10:00",
            closeTime: "20:00",
            address: "서울 성동구",
            roadAddress: "서울 성동구",
            region: "서울",
            latitude: 37.5,
            longitude: 127.0,
            instaPostId: nil,
            instaPostUrl: nil,
            captionSummary: "",
            imageUrlList: [],
            mediaType: .image,
            favoriteCount: favoriteCount,
            viewCount: 0,
            isFavorited: isFavorited,
            recommendList: []
        )
    }
}
