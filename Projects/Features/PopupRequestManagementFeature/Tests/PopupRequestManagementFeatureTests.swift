import ComposableArchitecture
import Domain
import Testing
@testable import PopupRequestManagementFeature

@MainActor
struct PopupRequestManagementFeatureTests {
    @Test("관리자 목록이 최초 진입 시 전체 제보를 로드한다")
    func loadsSubmissionListOnAppear() async {
        let expected = [
            PopupSubmissionListItem(
                id: 1,
                name: "성수 팝업",
                roadAddress: "서울 성동구 성수이로 00",
                region: "서울",
                submitterUserUuid: "user-1",
                submitterNickname: "팝팡",
                submittedAt: "2026-06-05T10:20:30",
                status: .pending
            ),
        ]

        let store = TestStore(
            initialState: PopupRequestManagementListFeature.State(adminUuid: "admin-1")
        ) {
            PopupRequestManagementListFeature()
        } withDependencies: {
            $0.popupRequestManagementClient.getPopupSubmissionList = { _, _ in expected }
        }

        await store.send(.onAppear) {
            $0.hasLoaded = true
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(.submissionsLoaded(expected.map(PopupRequestManagementListItem.init(item:)))) {
            $0.isLoading = false
            $0.allItems = expected.map(PopupRequestManagementListItem.init(item:))
            $0.errorMessage = nil
        }
    }

    @Test("관리자 플로우가 목록 선택 시 상세 표시 delegate를 올린다")
    func sendsShowDetailDelegateWhenSubmissionSelected() async {
        let store = TestStore(
            initialState: PopupRequestManagementFlowFeature.State(adminUuid: "admin-1")
        ) {
            PopupRequestManagementFlowFeature()
        }

        await store.send(.list(.delegate(.submissionSelected(7))))
        await store.receive(.delegate(.showDetail(7)))
    }
}
