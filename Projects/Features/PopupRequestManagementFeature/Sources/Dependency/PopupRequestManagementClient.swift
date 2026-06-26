import ComposableArchitecture
import Domain
import Foundation

public struct PopupRequestManagementClient: Sendable {
    var getPopupSubmissionList: @Sendable (_ adminUuid: String, _ filter: PopupSubmissionListFilter) async throws -> [PopupSubmissionListItem]
    var getPopupSubmissionDetail: @Sendable (_ adminUuid: String, _ submissionId: Int) async throws -> PopupSubmissionDetail
    var updatePopupSubmission: @Sendable (
        _ adminUuid: String,
        _ submissionId: Int,
        _ request: PopupSubmissionAdminUpdateRequest
    ) async throws -> PopupSubmissionAdminUpdateResult
}

extension PopupRequestManagementClient {
    public static func live(
        popupSubmissionUsecase: PopupSubmissionUsecaseProtocol
    ) -> Self {
        let box = PopupSubmissionUsecaseBox(popupSubmissionUsecase)

        return Self(
            getPopupSubmissionList: { adminUuid, filter in
                try await box.usecase.getPopupSubmissionList(adminUuid: adminUuid, filter: filter)
            },
            getPopupSubmissionDetail: { adminUuid, submissionId in
                try await box.usecase.getPopupSubmissionDetail(adminUuid: adminUuid, submissionId: submissionId)
            },
            updatePopupSubmission: { adminUuid, submissionId, request in
                try await box.usecase.updatePopupSubmission(
                    adminUuid: adminUuid,
                    submissionId: submissionId,
                    request: request
                )
            }
        )
    }
}

extension PopupRequestManagementClient: DependencyKey {
    public static let liveValue = PopupRequestManagementClient(
        getPopupSubmissionList: { _, _ in [] },
        getPopupSubmissionDetail: { _, _ in
            PopupSubmissionDetail(
                id: 0,
                name: "",
                startDate: Date(),
                endDate: Date(),
                roadAddress: "",
                region: "",
                description: "",
                recommendIdList: [],
                recommendList: [],
                imageList: [],
                address: nil,
                openTime: nil,
                closeTime: nil,
                instaPostUrl: nil,
                status: .pending
            )
        },
        updatePopupSubmission: { _, _, _ in
            PopupSubmissionAdminUpdateResult(popupUuid: nil)
        }
    )

#if DEBUG
    public static let previewValue = PopupRequestManagementClient(
        getPopupSubmissionList: { _, _ in
            [
                PopupSubmissionListItem(
                    id: 1,
                    name: "성수 스니커즈 팝업",
                    roadAddress: "서울 성동구 성수이로 00",
                    region: "서울",
                    submitterUserUuid: "user-1",
                    submitterNickname: "팝팡",
                    submittedAt: "2026-06-05T10:20:30",
                    status: .pending
                ),
                PopupSubmissionListItem(
                    id: 2,
                    name: "홍대 디저트 팝업",
                    roadAddress: "서울 마포구 와우산로 00",
                    region: "서울",
                    submitterUserUuid: "user-2",
                    submitterNickname: "디저트러버",
                    submittedAt: "2026-06-04T09:10:00",
                    status: .approved
                ),
            ]
        },
        getPopupSubmissionDetail: { _, submissionId in
            PopupSubmissionDetail(
                id: submissionId,
                name: "성수 스니커즈 팝업",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                roadAddress: "서울 성동구 성수이로 00",
                region: "서울",
                description: "브랜드 팝업 제보 원문입니다.",
                recommendIdList: [1, 2],
                recommendList: [
                    Recommend(id: 1, recommendName: "패션"),
                    Recommend(id: 2, recommendName: "라이프스타일"),
                ],
                imageList: [PopupSubmissionImage(imageUrl: "https://cdn.example.com/a.jpg", sortOrder: 0)],
                address: "서울 성동구 성수동 00-0",
                openTime: PopupSubmissionLocalTime(hour: 10, minute: 0),
                closeTime: PopupSubmissionLocalTime(hour: 20, minute: 0),
                instaPostUrl: "https://instagram.com/p/demo",
                status: .pending
            )
        },
        updatePopupSubmission: { _, _, _ in
            PopupSubmissionAdminUpdateResult(popupUuid: "popup-uuid-1")
        }
    )
#endif
}

extension PopupRequestManagementClient: TestDependencyKey {
    public static let testValue = PopupRequestManagementClient(
        getPopupSubmissionList: { _, _ in [] },
        getPopupSubmissionDetail: { _, _ in
            PopupSubmissionDetail(
                id: 0,
                name: "",
                startDate: Date(),
                endDate: Date(),
                roadAddress: "",
                region: "",
                description: "",
                recommendIdList: [],
                recommendList: [],
                imageList: [],
                address: nil,
                openTime: nil,
                closeTime: nil,
                instaPostUrl: nil,
                status: .pending
            )
        },
        updatePopupSubmission: { _, _, _ in PopupSubmissionAdminUpdateResult(popupUuid: nil) }
    )
}

extension DependencyValues {
    public var popupRequestManagementClient: PopupRequestManagementClient {
        get { self[PopupRequestManagementClient.self] }
        set { self[PopupRequestManagementClient.self] = newValue }
    }
}

private final class PopupSubmissionUsecaseBox: @unchecked Sendable {
    let usecase: PopupSubmissionUsecaseProtocol

    init(_ usecase: PopupSubmissionUsecaseProtocol) {
        self.usecase = usecase
    }
}
