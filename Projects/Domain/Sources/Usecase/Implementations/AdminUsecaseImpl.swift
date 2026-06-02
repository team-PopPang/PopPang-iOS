public final class AdminUsecaseImpl: AdminUsecaseProtocol {
    private let adminRepository: AdminRepositoryProtocol

    public init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }

    public func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid)
    }
}
