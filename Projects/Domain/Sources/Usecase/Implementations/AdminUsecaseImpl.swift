import Foundation

public final class AdminUsecaseImpl: AdminUsecaseProtocol {
    private let adminRepository: AdminRepositoryProtocol

    public init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }

    public func getPopupValidationList() async throws -> Data {
        try await adminRepository.getPopupValidationList()
    }

    public func validatePopup(parameters: [String: Any]) async throws {
        try await adminRepository.validatePopup(parameters: parameters)
    }

    public func registerPopup(parameters: [String: Any]) async throws {
        try await adminRepository.registerPopup(parameters: parameters)
    }

    public func uploadPopupImages(popupUuid: String, images: [AdminPopupImageUploadItem]) async throws {
        try await adminRepository.uploadPopupImages(popupUuid: popupUuid, images: images)
    }

    public func registerPopupRecommendations(popupUuid: String, recommendIds: [Int]) async throws {
        try await adminRepository.registerPopupRecommendations(popupUuid: popupUuid, recommendIds: recommendIds)
    }

    public func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid)
    }
}
