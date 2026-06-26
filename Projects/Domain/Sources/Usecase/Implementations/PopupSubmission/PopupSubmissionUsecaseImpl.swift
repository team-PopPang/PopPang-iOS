import Foundation

public final class PopupSubmissionUsecaseImpl: PopupSubmissionUsecaseProtocol {
    private let repository: PopupSubmissionRepositoryProtocol

    public init(repository: PopupSubmissionRepositoryProtocol) {
        self.repository = repository
    }

    public func getPopupSubmissionList(
        adminUuid: String,
        filter: PopupSubmissionListFilter
    ) async throws -> [PopupSubmissionListItem] {
        try await repository.getPopupSubmissionList(adminUuid: adminUuid, filter: filter)
    }

    public func getPopupSubmissionDetail(
        adminUuid: String,
        submissionId: Int
    ) async throws -> PopupSubmissionDetail {
        try await repository.getPopupSubmissionDetail(adminUuid: adminUuid, submissionId: submissionId)
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await repository.createPopupSubmission(request)
    }

    public func updatePopupSubmission(
        adminUuid: String,
        submissionId: Int,
        request: PopupSubmissionAdminUpdateRequest
    ) async throws -> PopupSubmissionAdminUpdateResult {
        try await repository.updatePopupSubmission(
            adminUuid: adminUuid,
            submissionId: submissionId,
            request: request
        )
    }
}
