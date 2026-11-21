import ComposableArchitecture
import Core
import Domain
import Foundation
import Testing
@testable import MapFeatureV2

@MainActor
struct MapFeatureTests {
    @Test("처음 열면 지역·카테고리를 받고, 위치를 받은 뒤 가까운순으로 위치를 담아 조회한다")
    func firstLoadWaitsForLocationThenSearches() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.isWaitingForUserLocation)
        #expect(queries.value.isEmpty)

        await store.send(.userLocationChanged(MapCoordinate(latitude: 37.5, longitude: 127.0)))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.first?.sort == .closest)
        #expect(queries.value.first?.latitude == 37.5)
        #expect(queries.value.first?.region == "전체")
        #expect(store.state.popups == [.fixture()])
        #expect(store.state.totalCount == 1)
        #expect(store.state.categories.map(\.name) == ["디저트"])
        #expect(store.state.isLoading == false)
    }

    @Test("필터를 적용하면 필터를 조회 조건에 담아 다시 조회하고, 앱에서 목록을 거르지 않는다")
    func filterIsSentAsQuery() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        let store = TestStore(initialState: Self.loadedState()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture(), .fixture(uuid: "popup-2")], totalCount: 2)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        let filter = MapPopupFilter(categoryIds: [1, 3])
        await store.send(.filterApplied(filter))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.last?.filter == filter)
        // 서버가 준 결과를 그대로 보여 준다.
        #expect(store.state.popups.count == 2)
        #expect(store.state.totalCount == 2)
    }

    @Test("카테고리(마커 색)는 지도 탭에 처음 들어갈 때 한 번 받고, 다시 들어와도 받지 않는다")
    func categoriesLoadOnce() async {
        let categoryCalls = LockIsolated(0)
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(getMapCategoryList: {
                categoryCalls.withValue { $0 += 1 }
                return [MapCategory(id: 1, name: "디저트", colorHex: "#7A8B3C")]
            })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)
        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(categoryCalls.value == 1)
        #expect(store.state.categories == [MapCategory(id: 1, name: "디저트", colorHex: "#7A8B3C")])
    }

    @Test("처음에 카테고리를 받지 못했으면 다음에 탭에 들어올 때 다시 받는다")
    func categoriesRetryAfterFailure() async {
        let categoryCalls = LockIsolated(0)
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(getMapCategoryList: {
                let call = categoryCalls.withValue { $0 += 1; return $0 }
                if call == 1 { throw PopupError.failed }
                return [MapCategory(id: 1, name: "디저트", colorHex: "#7A8B3C")]
            })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)
        #expect(store.state.categories.isEmpty)
        #expect(store.state.regions.isEmpty == false)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)
        #expect(categoryCalls.value == 2)
        #expect(store.state.categories.map(\.id) == [1])
    }

    @Test("마커 색은 팝업 카테고리 이름으로 찾고, 필터로 고른 카테고리를 먼저 보며, 맞는 카테고리가 없으면 없다")
    func markerColorRule() {
        let categories = [
            MapCategory(id: 1, name: "디저트", colorHex: "#7A8B3C"),
            MapCategory(id: 2, name: "캐릭터", colorHex: "#2563EB"),
        ]
        let both = Popup.fixture(recommendList: ["디저트", " 캐릭터 "])

        #expect(MapMarkerColor.colorHex(for: both, categories: categories, selectedIds: []) == "#7A8B3C")
        #expect(MapMarkerColor.colorHex(for: both, categories: categories, selectedIds: [2]) == "#2563EB")
        #expect(MapMarkerColor.colorHex(for: .fixture(recommendList: ["없는 카테고리", "캐릭터"]), categories: categories, selectedIds: []) == "#2563EB")
        #expect(MapMarkerColor.colorHex(for: .fixture(recommendList: ["없는 카테고리"]), categories: categories, selectedIds: []) == nil)
        #expect(MapMarkerColor.colorHex(for: .fixture(recommendList: []), categories: categories, selectedIds: []) == nil)

        var state = Self.loadedState()
        state.categories = categories
        state.popups = [both, .fixture(uuid: "popup-2", recommendList: [])]
        state.filter = MapPopupFilter(categoryIds: [2])
        #expect(state.markerColors == ["popup-1": "#2563EB"])
    }

    @Test("서버 색 문자열을 색으로 바꾸고, 형식이 다르면 nil이다")
    func markerHexParsing() {
        #expect(MapMarkerRenderer.color(hex: "#7A8B3C") != nil)
        #expect(MapMarkerRenderer.color(hex: "16A34A") != nil)
        #expect(MapMarkerRenderer.color(hex: "#GGGGGG") == nil)
        #expect(MapMarkerRenderer.color(hex: "#FFF") == nil)
    }

    @Test("마커 이름표는 보일 때만 그리고, 이름표가 없어도 좌표는 동그라미 가운데에 둔다")
    func markerLabelVisibility() {
        let withLabel = MapMarkerRenderer.image(colorHex: "#7A8B3C", name: "두바이쫀득쿠키", style: .normal, showsLabel: true)
        let withoutLabel = MapMarkerRenderer.image(colorHex: "#7A8B3C", name: "두바이쫀득쿠키", style: .normal, showsLabel: false)

        #expect(withoutLabel.image.size.height < withLabel.image.size.height)
        #expect(withoutLabel.ringCenterY == withLabel.ringCenterY)
        #expect(withoutLabel.image.size.height == withoutLabel.ringCenterY * 2)
        // 이름표가 없으면 이름이 달라도 같은 그림을 다시 쓴다.
        let otherName = MapMarkerRenderer.image(colorHex: "#7A8B3C", name: "다른 팝업", style: .normal, showsLabel: false)
        #expect(otherName.image === withoutLabel.image)
        #expect(NaverMapCoordinator.labelMinZoom == 14)
    }

    @Test("가까운순 결과가 비면 최신순으로 다시 조회한다")
    func closestFallsBackToNewest() async {
        let sorts = LockIsolated<[MapSortOption]>([])
        let store = TestStore(initialState: Self.loadedState()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    sorts.withValue { $0.append(query.sort) }
                    return query.sort == .closest
                        ? MapPopupSearchResult(items: [], totalCount: 0)
                        : MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.filterApplied(MapPopupFilter()))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(sorts.value == [.closest, .newest])
        #expect(store.state.popups == [.fixture()])
    }

    @Test("가까운순에서 지도를 1km 넘게 옮기면 멈춘 뒤 그 중심으로 다시 조회하고, 그보다 적게 옮기면 조회하지 않는다")
    func movingMapRefetchesForClosest() async {
        let clock = TestClock()
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.5005, longitude: 127.0)))
        await clock.advance(by: .seconds(1))
        #expect(queries.value.isEmpty)

        // 약 550m. 예전 기준(300m)이면 다시 받았지만 1km 기준이라 받지 않는다.
        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.505, longitude: 127.0)))
        await clock.advance(by: .seconds(1))
        #expect(queries.value.isEmpty)

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.51, longitude: 127.0)))
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.last?.latitude == 37.51)
        #expect(store.state.searchedCenter == MapCoordinate(latitude: 37.51, longitude: 127.0))
    }

    @Test("검색어를 입력만 하면 조회하지 않고, 검색을 누르면 앞뒤 공백을 뺀 검색어를 담아 지금 조건으로 다시 조회한다")
    func submittingSearchSendsKeyword() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.filter = MapPopupFilter(categoryIds: [3])
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [], totalCount: 0)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.searchTextChanged(" 딸기 "))
        #expect(queries.value.isEmpty)

        await store.send(.searchSubmitted)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        // 검색 결과가 비어도 최신순으로 다시 묻지 않는다.
        #expect(queries.value.count == 1)
        #expect(queries.value.first?.keyword == "딸기")
        #expect(queries.value.first?.filter.categoryIds == [3])
        #expect(store.state.appliedKeyword == "딸기")
    }

    @Test("검색이 실패했으면 같은 검색어로 검색을 다시 누를 때 다시 조회한다")
    func resubmittingAfterFailureRetries() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.searchText = "딸기"
        state.appliedKeyword = "딸기"
        state.errorMessage = "팝업을 불러오지 못했어요."
        state.lastSearchFailed = true
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.searchSubmitted)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.first?.keyword == "딸기")
    }

    @Test("검색과 상관없는 오류(찜 실패)가 있어도 같은 검색어면 다시 조회하지 않는다")
    func resubmittingSameKeywordWithUnrelatedErrorSkips() async {
        var state = Self.loadedState()
        state.searchText = "딸기"
        state.appliedKeyword = "딸기"
        state.errorMessage = "찜하지 못했어요."
        let store = TestStore(initialState: state) {
            MapFeature()
        }
        await store.send(.searchSubmitted)
    }

    @Test("팝업을 고르면 그 위치를 다시 받기 기준으로 삼고, 카드를 보는 동안 손으로 옮긴 위치는 기준으로 삼지 않는다")
    func selectedPopupBecomesRefetchBase() async {
        var state = Self.loadedState()
        state.popups = [.fixture()]
        state.searchedCenter = MapCoordinate(latitude: 35.1, longitude: 129.0)
        let store = TestStore(initialState: state) {
            MapFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.mapMarkerTapped(.fixture()))
        #expect(store.state.refetchBaseCenter == MapCoordinate(latitude: 37.5, longitude: 127.0))
        // 목록을 받은 위치는 그대로다.
        #expect(store.state.searchedCenter == MapCoordinate(latitude: 35.1, longitude: 129.0))

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.6, longitude: 127.1)))
        #expect(store.state.refetchBaseCenter == MapCoordinate(latitude: 37.5, longitude: 127.0))
    }

    @Test("검색 중에 내 위치 버튼처럼 코드로 지도를 1km 넘게 옮기면 검색을 두고 새 위치에서 같은 검색어로 받는다")
    func programmaticMoveKeepsSearch() async {
        let clock = TestClock()
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.searchText = "딸기"
        state.appliedKeyword = "딸기"
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.51, longitude: 127.0), byGesture: false))
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.first?.keyword == "딸기")
        #expect(store.state.searchText == "딸기")
    }

    @Test("팝업을 보는 중에 늦게 온 목록 응답은 고른 팝업 기준점을 덮지 않는다")
    func lateResponseKeepsPopupBase() async {
        var state = Self.loadedState()
        state.popups = [.fixture()]
        state.selectedPopupUuid = Popup.fixture().popupUuid
        state.refetchBaseCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        let store = TestStore(initialState: state) {
            MapFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.searchResultLoaded(MapPopupSearchResult(items: [.fixture()], totalCount: 1), center: MapCoordinate(latitude: 35.1, longitude: 129.0)))
        #expect(store.state.refetchBaseCenter == MapCoordinate(latitude: 37.5, longitude: 127.0))
    }

    @Test("지역 목록을 받기 전에는 검색을 눌러도 조회하지 않고 검색어만 정해 둔다")
    func submittingBeforeRegionsLoadedDoesNotFetch() async {
        var state = MapFeature.State()
        state.searchText = "성수"
        let store = TestStore(initialState: state) {
            MapFeature()
        }
        await store.send(.searchSubmitted) {
            $0.appliedKeyword = "성수"
        }
    }

    @Test("지도를 옮겨 검색을 풀 때, 검색창에 새로 입력하던 글자는 남긴다")
    func movingMapKeepsUnsubmittedText() async {
        let clock = TestClock()
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.searchText = "성수동 카페"
        state.appliedKeyword = "성수"
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.mapFeatureClient = .mock(
                searchMapPopups: { _ in MapPopupSearchResult(items: [], totalCount: 0) }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.51, longitude: 127.0)))
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(store.state.appliedKeyword == nil)
        #expect(store.state.searchText == "성수동 카페")
    }

    @Test("검색어를 다 지우면 검색 없이 다시 조회한다")
    func clearingSearchRefetchesWithoutKeyword() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.searchText = "딸기"
        state.appliedKeyword = "딸기"
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.searchTextChanged(""))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.first?.keyword == nil)
        #expect(store.state.appliedKeyword == nil)
    }

    @Test("검색 중에 지도를 1km 넘게 옮기면 검색을 풀고 새 위치의 전체 목록을 받는다")
    func movingMapClearsSearch() async {
        let clock = TestClock()
        let queries = LockIsolated<[MapPopupQuery]>([])
        var state = Self.loadedState()
        state.searchedCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        state.searchText = "딸기"
        state.appliedKeyword = "딸기"
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.51, longitude: 127.0)))
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.first?.keyword == nil)
        #expect(store.state.searchText.isEmpty)
        #expect(store.state.appliedKeyword == nil)
    }

    @Test("마커를 누르면 미리보기 팝업이 정해지고, 상세보기는 delegate로 올린다")
    func markerSelectionAndDetail() async {
        var state = Self.loadedState()
        state.popups = [.fixture()]
        let store = TestStore(initialState: state) {
            MapFeature()
        }

        await store.send(.mapMarkerTapped(.fixture())) {
            $0.selectedPopupUuid = "popup-1"
            // 고른 팝업 위치를 다시 받기 기준으로 삼는다.
            $0.refetchBaseCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        }
        #expect(store.state.selectedPopup == .fixture())

        await store.send(.popupDetailTapped(.fixture()))
        await store.receive(\.delegate)

        await store.send(.previewDismissed) {
            $0.selectedPopupUuid = nil
        }
    }

    @Test("찜 응답을 기다리는 동안 같은 하트를 다시 누르면 요청을 다시 보내지 않는다")
    func favoriteIgnoresDoubleTap() async {
        let clock = TestClock()
        let calls = LockIsolated<[String]>([])
        var state = Self.loadedState()
        state.popups = [.fixture(favoriteCount: 3)]
        let store = TestStore(initialState: state) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                addFavorite: { uuid in
                    calls.withValue { $0.append("add:\(uuid)") }
                    try await clock.sleep(for: .seconds(1))
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.toggleLike(.fixture()))
        await store.send(.toggleLike(.fixture()))
        await clock.advance(by: .seconds(1))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(calls.value == ["add:popup-1"])
        #expect(store.state.popups.first?.isFavorited == true)
        #expect(store.state.popups.first?.favoriteCount == 4)
        #expect(store.state.favoriteInFlight.isEmpty)
    }

    @Test("조회가 실패하면 안내 문구를, 로그인이 끊기면 문구 없이 둔다")
    func searchFailureMessages() async {
        let failing = TestStore(initialState: Self.loadedState()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(searchMapPopups: { _ in throw PopupError.failed })
        }
        failing.exhaustivity = .off(showSkippedAssertions: false)
        await failing.send(.filterApplied(MapPopupFilter()))
        await failing.finish()
        await failing.skipReceivedActions(strict: false)
        #expect(failing.state.errorMessage == MapFeature.loadFailedMessage)
        #expect(failing.state.isLoading == false)

        let loggedOut = TestStore(initialState: Self.loadedState()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(searchMapPopups: { _ in throw AuthSessionError.loginRequired })
        }
        loggedOut.exhaustivity = .off(showSkippedAssertions: false)
        await loggedOut.send(.filterApplied(MapPopupFilter()))
        await loggedOut.finish()
        await loggedOut.skipReceivedActions(strict: false)
        #expect(loggedOut.state.errorMessage == nil)
    }

    @Test("지역 목록을 받기 전에 위치 권한이 거부돼도 최신순으로 바꿔 두고, 지역을 받으면 최신순으로 조회한다")
    func permissionDeniedBeforeRegionsLoaded() async {
        let queries = LockIsolated<[MapPopupQuery]>([])
        let store = TestStore(initialState: MapFeature.State()) {
            MapFeature()
        } withDependencies: {
            $0.mapFeatureClient = .mock(
                searchMapPopups: { query in
                    queries.withValue { $0.append(query) }
                    return MapPopupSearchResult(items: [.fixture()], totalCount: 1)
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.locationPermissionDenied)
        #expect(store.state.sort == .newest)

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.map(\.sort) == [.newest])
        #expect(store.state.isWaitingForUserLocation == false)
        #expect(store.state.isLoading == false)
    }

    /// 지역을 받고 위치도 아는 상태.
    static func loadedState() -> MapFeature.State {
        var state = MapFeature.State()
        state.regions = [RegionList(region: "전체", districtList: ["전체"])]
        state.selectedRegion = state.regions.first
        state.selectedDistrict = "전체"
        state.hasUserLocation = true
        state.mapCenter = MapCoordinate(latitude: 37.5, longitude: 127.0)
        return state
    }
}

private extension MapFeatureClient {
    static func mock(
        getRegionList: @escaping @Sendable () async throws -> [RegionList] = { [RegionList(region: "전체", districtList: ["전체"])] },
        getMapCategoryList: @escaping @Sendable () async throws -> [MapCategory] = { [MapCategory(id: 1, name: "디저트", colorHex: "#7A8B3C")] },
        searchMapPopups: @escaping @Sendable (MapPopupQuery) async throws -> MapPopupSearchResult = { _ in
            MapPopupSearchResult(items: [], totalCount: 0)
        },
        addFavorite: @escaping @Sendable (String) async throws -> Void = { _ in },
        removeFavorite: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> Self {
        Self(
            getRegionList: getRegionList,
            getMapCategoryList: getMapCategoryList,
            searchMapPopups: searchMapPopups,
            addFavorite: addFavorite,
            removeFavorite: removeFavorite
        )
    }
}

private extension Popup {
    static func fixture(uuid: String = "popup-1", favoriteCount: Int = 0, recommendList: [String] = ["디저트"]) -> Popup {
        let start = Calendar.current.startOfDay(for: Date())
        return Popup(
            popupUuid: uuid,
            name: "성수 팝업",
            startDate: start,
            endDate: start.addingTimeInterval(86_400 * 3),
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
            isFavorited: false,
            recommendList: recommendList
        )
    }
}
