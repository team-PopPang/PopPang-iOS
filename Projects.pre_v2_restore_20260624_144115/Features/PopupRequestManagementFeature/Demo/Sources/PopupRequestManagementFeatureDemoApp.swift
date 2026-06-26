import Domain
import PopupRequestManagementFeature
import PopupRequestManagementFeatureInterface
import SwiftUI

@main
struct PopupRequestManagementFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(MockAdminUsecase(), for: AdminUsecaseProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PopupRequestManagementFeatureView(router: PopupRequestManagementFeatureDemoRouter())
            }
        }
    }
}

@MainActor
private final class PopupRequestManagementFeatureDemoRouter: PopupRequestManagementFeatureRouting {
    func route(to route: PopupRequestManagementFeatureRoute) {}
}

private struct MockAdminUsecase: AdminUsecaseProtocol {
    func getPopupSubmissionList() async throws -> [PopupSubmission] {
        [
            PopupSubmission(
                id: 1,
                name: "성수 스니커즈 팝업",
                startDate: "2026-06-05",
                endDate: "2026-06-15",
                address: "서울 성동구 성수이로 00",
                description: "브랜드 스니커즈 팝업 제보",
                status: .pending,
                createdAt: "2026-06-05T10:20:30.000Z"
            ),
            PopupSubmission(
                id: 2,
                name: "홍대 디저트 팝업",
                startDate: "2026-06-04",
                endDate: "2026-06-12",
                address: "서울 마포구 와우산로 00",
                description: "디저트 팝업 제보",
                status: .approved,
                createdAt: "2026-06-04T09:10:00.000Z"
            ),
            PopupSubmission(
                id: 3,
                name: "부산 라이프스타일 팝업",
                startDate: "2026-06-03",
                endDate: "2026-06-09",
                address: "부산 해운대구 센텀로 00",
                description: "라이프스타일 팝업 제보",
                status: .rejected,
                createdAt: "2026-06-03T08:00:00.000Z"
            ),
        ]
    }

    func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {}

    @available(*, deprecated, message: "토큰 기반 V2 deactivatePopup(popupUuid:)를 사용하세요.")
    func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws {}

    func deactivatePopup(popupUuid: String) async throws {}

    func updatePopupSubmissionStatus(submissionId: Int, status: PopupSubmissionStatus) async throws {}
}
