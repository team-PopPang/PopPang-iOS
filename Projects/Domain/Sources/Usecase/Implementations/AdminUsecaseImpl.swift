import Foundation

public final class AdminUsecaseImpl: AdminUsecaseProtocol {
    private let adminRepository: AdminRepositoryProtocol

    public init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }

    public func deactivatePopup(popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(popupUuid: popupUuid)
    }

}
