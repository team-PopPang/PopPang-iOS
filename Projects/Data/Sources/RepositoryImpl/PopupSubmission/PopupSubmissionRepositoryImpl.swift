import Core
import Domain
import Foundation
import Moya

public final class PopupSubmissionRepositoryImpl: PopupSubmissionRepositoryProtocol {
    public init() {}

    public func getPopupSubmissionList(
        adminUuid: String,
        filter: PopupSubmissionListFilter
    ) async throws -> [PopupSubmissionListItem] {
        let dtos = try await provider.asyncRequest(
            .getPopupSubmissionList(adminUuid: adminUuid, status: filter.rawValue),
            decodeTo: [PopupSubmissionAdminListResponseDTO].self
        )

        return try dtos.map { try $0.toEntity() }
    }

    public func getPopupSubmissionDetail(
        adminUuid: String,
        submissionId: Int
    ) async throws -> PopupSubmissionDetail {
        let dto = try await provider.asyncRequest(
            .getPopupSubmissionDetail(adminUuid: adminUuid, submissionId: submissionId),
            decodeTo: PopupSubmissionAdminDetailResponseDTO.self
        )

        return try dto.toEntity()
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await provider.asyncRequestVoid(.createPopupSubmission(requestDTO: request.toDTO()))
    }

    public func updatePopupSubmission(
        adminUuid: String,
        submissionId: Int,
        request: PopupSubmissionAdminUpdateRequest
    ) async throws -> PopupSubmissionAdminUpdateResult {
        let dto = try await provider.asyncRequest(
            .updatePopupSubmission(
                adminUuid: adminUuid,
                submissionId: submissionId,
                requestDTO: request.toDTO()
            ),
            decodeTo: PopupSubmissionAdminUpdateResponseDTO.self
        )

        return dto.toEntity()
    }

    private var provider: MoyaProvider<PopupSubmissionAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
