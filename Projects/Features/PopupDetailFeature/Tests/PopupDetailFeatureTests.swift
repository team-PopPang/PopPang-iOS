import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import PopupDetailFeature

@MainActor
struct PopupDetailFeatureTests {
    @Test("S04 화면이 열리면 popupUuid로 상세를 받아 로딩에서 내용으로 바뀌고, 조회 기록과 관련 팝업도 보낸다")
    func s04LoadsDetailFromPopupUuid() async {
        let requested = LockIsolated<[String]>([])
        let store = TestStore(initialState: PopupDetailFeature.State(popupUuid: "popup-1")) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(
                getPopupDetail: { uuid in
                    requested.withValue { $0.append("detail:\(uuid)") }
                    return .sample
                },
                increaseViewCount: { uuid in requested.withValue { $0.append("view:\(uuid)") } },
                getRelatedPopupList: { uuid in
                    requested.withValue { $0.append("related:\(uuid)") }
                    return [.popupMock]
                }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        #expect(store.state.detailState == .loading)
        await store.send(.onAppear) {
            $0.hasLoaded = true
        }
        // 세 요청은 따로 보내므로 응답 순서는 정해져 있지 않다. 받은 action을 모두 반영한 뒤의 상태를 본다.
        await store.finish()
        await store.skipReceivedActions(strict: false)
        #expect(store.state.detailState == .loaded(.sample))
        #expect(store.state.relatedPopupList == [.popupMock])
        #expect(Set(requested.value) == ["detail:popup-1", "view:popup-1", "related:popup-1"])
    }

    @Test("S04 없는 팝업이면 찾을 수 없음 화면을 보여 주고 다시 시도는 하지 않는다")
    func s04NotFoundShowsNotFound() async {
        let detailCalls = LockIsolated(0)
        let store = TestStore(initialState: PopupDetailFeature.State(popupUuid: "popup-1")) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(getPopupDetail: { _ in
                detailCalls.withValue { $0 += 1 }
                throw PopupError.notFound
            })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.receive(\.detailFailed) {
            $0.detailState = .failed(.notFound)
        }
        await store.send(.retryTapped)
        await store.finish()
        #expect(store.state.detailState == .failed(.notFound))
        #expect(detailCalls.value == 1)
    }

    @Test("S04 그 밖의 실패면 다시 시도 화면을 보여 주고, 다시 시도하면 상세만 다시 받는다")
    func s04FailureCanRetry() async {
        let detailCalls = LockIsolated(0)
        let viewCalls = LockIsolated(0)
        let store = TestStore(initialState: PopupDetailFeature.State(popupUuid: "popup-1")) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(
                getPopupDetail: { _ in
                    let count = detailCalls.withValue { $0 += 1; return $0 }
                    if count == 1 { throw PopupError.failed }
                    return .sample
                },
                increaseViewCount: { _ in viewCalls.withValue { $0 += 1 } }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.receive(\.detailFailed) {
            $0.detailState = .failed(.failed)
        }
        await store.send(.retryTapped) {
            $0.detailState = .loading
        }
        await store.receive(\.detailLoaded) {
            $0.detailState = .loaded(.sample)
        }
        await store.finish()
        #expect(detailCalls.value == 2)
        #expect(viewCalls.value == 1)
    }

    @Test("S04 관련 팝업이나 조회 기록이 실패해도 상세 내용은 보여 준다")
    func s04RelatedFailureKeepsDetail() async {
        let store = TestStore(initialState: PopupDetailFeature.State(popupUuid: "popup-1")) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(
                getPopupDetail: { _ in .sample },
                increaseViewCount: { _ in throw PopupError.failed },
                getRelatedPopupList: { _ in throw PopupError.failed }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.receive(\.detailLoaded) {
            $0.detailState = .loaded(.sample)
        }
        await store.finish()
        #expect(store.state.detailState == .loaded(.sample))
        #expect(store.state.relatedPopupList.isEmpty)
    }

    @Test("S04 하트를 누르면 바로 바꾸고 목록에 알리며, 실패하면 되돌린다")
    func s04ToggleLikeRevertsOnFailure() async {
        var state = PopupDetailFeature.State(popupUuid: "popup-1")
        state.detailState = .loaded(.sample)
        let store = TestStore(initialState: state) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(addFavorite: { _ in throw PopupError.failed })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        var liked = PopupDetail.sample
        liked.isFavorited = true
        liked.favoriteCount = 13

        await store.send(.toggleLike) {
            $0.detailState = .loaded(liked)
        }
        await store.receive(\.delegate, .favoriteChanged(popupUuid: "popup-1", isFavorited: true, favoriteCount: 13))
        await store.receive(\.favoriteUpdated) {
            $0.detailState = .loaded(.sample)
        }
        await store.receive(\.delegate, .favoriteChanged(popupUuid: "popup-1", isFavorited: false, favoriteCount: 12))
        await store.finish()
    }

    @Test("S04 불러오기 전에는 하트와 비활성화가 동작하지 않는다")
    func s04ActionsNeedLoadedDetail() async {
        let store = TestStore(initialState: PopupDetailFeature.State(popupUuid: "popup-1")) {
            PopupDetailFeature()
        }

        await store.send(.toggleLike)
        await store.send(.deactivatePopup)
    }

    @Test("S04 관리자 비활성화가 성공하면 완료로 바꾼다")
    func s04DeactivateCompletes() async {
        let deactivated = LockIsolated<[String]>([])
        var state = PopupDetailFeature.State(popupUuid: "popup-1")
        state.detailState = .loaded(.sample)
        let store = TestStore(initialState: state) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .mock(deactivatePopup: { uuid in deactivated.withValue { $0.append(uuid) } })
        }

        await store.send(.deactivatePopup) {
            $0.isDeactivating = true
        }
        await store.receive(\.deactivateCompleted) {
            $0.isDeactivating = false
            $0.didDeactivate = true
        }
        #expect(deactivated.value == ["popup-1"])
    }
}

private extension PopupDetail {
    static let sample = PopupDetail(
        popupUuid: "popup-1",
        name: "성수 팝업",
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 86_400),
        openTime: "10:00",
        closeTime: "20:00",
        address: "서울 성동구",
        roadAddress: "서울 성동구",
        region: "서울",
        latitude: nil,
        longitude: nil,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "요약",
        imageUrlList: [],
        mediaType: .image,
        favoriteCount: 12,
        viewCount: 34,
        isFavorited: false,
        recommendList: []
    )
}

private extension PopupDetailClient {
    static func mock(
        getPopupDetail: @escaping @Sendable (String) async throws -> PopupDetail = { _ in .sample },
        increaseViewCount: @escaping @Sendable (String) async throws -> Void = { _ in },
        getRelatedPopupList: @escaping @Sendable (String) async throws -> [Popup] = { _ in [] },
        addFavorite: @escaping @Sendable (String) async throws -> Void = { _ in },
        removeFavorite: @escaping @Sendable (String) async throws -> Void = { _ in },
        deactivatePopup: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> Self {
        PopupDetailClient(
            getPopupDetail: getPopupDetail,
            increaseViewCount: increaseViewCount,
            getRelatedPopupList: getRelatedPopupList,
            addFavorite: addFavorite,
            removeFavorite: removeFavorite,
            deactivatePopup: deactivatePopup
        )
    }
}
