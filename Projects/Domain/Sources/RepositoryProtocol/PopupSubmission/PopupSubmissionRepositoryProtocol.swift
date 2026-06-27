import Foundation

public protocol PopupSubmissionRepositoryProtocol {
    func getPopupSubmissionList(
        adminUuid: String,
        filter: PopupSubmissionListFilter
    ) async throws -> [PopupSubmissionListItem]

    func getPopupSubmissionDetail(
        adminUuid: String,
        submissionId: Int
    ) async throws -> PopupSubmissionDetail

    func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws

    func updatePopupSubmission(
        adminUuid: String,
        submissionId: Int,
        request: PopupSubmissionAdminUpdateRequest
    ) async throws -> PopupSubmissionAdminUpdateResult
}
