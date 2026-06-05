import Foundation

public final class AdminUsecaseImpl: AdminUsecaseProtocol {
    private let adminRepository: AdminRepositoryProtocol

    public init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }

    public func getPopupSubmissionList() async throws -> [PopupSubmission] {
        try await adminRepository.getPopupSubmissionList()
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await adminRepository.createPopupSubmission(request)
    }

    public func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws {
        try await adminRepository.deactivatePopupByUser(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func deactivatePopup(popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(popupUuid: popupUuid)
    }

    public func updatePopupSubmissionStatus(submissionId: Int, status: PopupSubmissionStatus) async throws {
        try await adminRepository.updatePopupSubmissionStatus(submissionId: submissionId, status: status)
    }
}
