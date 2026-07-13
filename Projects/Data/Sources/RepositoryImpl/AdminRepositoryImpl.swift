import Core
import Domain
import Foundation
import Moya

public final class AdminRepositoryImpl: AdminRepositoryProtocol {
    public init() {}

    public func getPopupSubmissionList() async throws -> [PopupSubmission] {
        let dtos = try await adminProvider.asyncRequest(
            .getPopupSubmissionList,
            decodeTo: [PopupSubmissionDTO].self
        )

        return try dtos.map { try $0.toEntity() }
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await adminProvider.asyncRequestVoid(.createPopupSubmission(requestDTO: request.toDTO()))
    }

    @available(*, deprecated, message: "deactivatePopup(adminUuid:popupUuid:)를 사용하세요.")
    public func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(.deactivatePopupByUser(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func deactivatePopup(adminUuid: String, popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(
            .deactivatePopup(adminUuid: adminUuid, popupUuid: popupUuid)
        )
    }

    public func updatePopupSubmissionStatus(submissionId: Int, status: PopupSubmissionStatus) async throws {
        try await adminProvider.asyncRequestVoid(
            .updatePopupSubmissionStatus(
                submissionId: submissionId,
                requestDTO: status.toDTO()
            )
        )
    }

    private var adminProvider: MoyaProvider<AdminAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
