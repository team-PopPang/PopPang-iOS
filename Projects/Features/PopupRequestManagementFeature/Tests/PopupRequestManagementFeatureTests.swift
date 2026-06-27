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

        let mapped = expected.map(PopupRequestManagementListItem.init(item:))

        await store.receive(.submissionsLoaded(summaryItems: mapped, items: mapped)) {
            $0.isLoading = false
            $0.allItems = mapped
            $0.items = mapped
            $0.errorMessage = nil
        }
    }

    @Test("필터 선택 시 서버 필터 기준으로 최신 목록을 재조회한다")
    func reloadsListWhenFilterChanges() async {
        let allItems = [
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
            PopupSubmissionListItem(
                id: 2,
                name: "홍대 팝업",
                roadAddress: "서울 마포구 와우산로 00",
                region: "서울",
                submitterUserUuid: "user-2",
                submitterNickname: "홍대러버",
                submittedAt: "2026-06-04T09:10:00",
                status: .approved
            ),
        ]

        let approvedItems = [allItems[1]]

        let store = TestStore(
            initialState: PopupRequestManagementListFeature.State(adminUuid: "admin-1")
        ) {
            PopupRequestManagementListFeature()
        } withDependencies: {
            $0.popupRequestManagementClient.getPopupSubmissionList = { _, filter in
                switch filter {
                case .all:
                    return allItems
                case .approved:
                    return approvedItems
                case .pending, .rejected:
                    return []
                }
            }
        }

        await store.send(.filterSelected(.approved)) {
            $0.selectedFilter = .approved
            $0.isLoading = true
            $0.errorMessage = nil
        }

        let mappedAll = allItems.map(PopupRequestManagementListItem.init(item:))
        let mappedApproved = approvedItems.map(PopupRequestManagementListItem.init(item:))

        await store.receive(.submissionsLoaded(summaryItems: mappedAll, items: mappedApproved)) {
            $0.isLoading = false
            $0.allItems = mappedAll
            $0.items = mappedApproved
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
