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
        #expect(store.state.categories.map(\.recommendName) == ["디저트"])
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

        let filter = MapPopupFilter(categoryIds: [1], status: .endingThisWeek, period: .thisWeek)
        await store.send(.filterApplied(filter))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.last?.filter == filter)
        // 서버가 준 결과를 그대로 보여 준다.
        #expect(store.state.popups.count == 2)
        #expect(store.state.totalCount == 2)
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

    @Test("가까운순에서 지도를 300m 넘게 옮기면 멈춘 뒤 그 중심으로 다시 조회하고, 조금 옮기면 조회하지 않는다")
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

        await store.send(.mapCenterChanged(MapCoordinate(latitude: 37.51, longitude: 127.0)))
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        await store.skipReceivedActions(strict: false)

        #expect(queries.value.count == 1)
        #expect(queries.value.last?.latitude == 37.51)
        #expect(store.state.searchedCenter == MapCoordinate(latitude: 37.51, longitude: 127.0))
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
        getRecommendList: @escaping @Sendable () async throws -> [Recommend] = { [Recommend(id: 1, recommendName: "디저트")] },
        searchMapPopups: @escaping @Sendable (MapPopupQuery) async throws -> MapPopupSearchResult = { _ in
            MapPopupSearchResult(items: [], totalCount: 0)
        },
        addFavorite: @escaping @Sendable (String) async throws -> Void = { _ in },
        removeFavorite: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> Self {
        Self(
            getRegionList: getRegionList,
            getRecommendList: getRecommendList,
            searchMapPopups: searchMapPopups,
            addFavorite: addFavorite,
            removeFavorite: removeFavorite
        )
    }
}

private extension Popup {
    static func fixture(uuid: String = "popup-1", favoriteCount: Int = 0) -> Popup {
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
            recommendList: ["디저트"]
        )
    }
}
