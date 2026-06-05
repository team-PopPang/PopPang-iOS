import Core
import Domain
import Foundation
import Moya

public final class AdminRepositoryImpl: AdminRepositoryProtocol {
    public init() {}

    public func getPopupSubmissionList() async throws -> [PopupSubmission] {
        try await adminProvider.asyncRequest(
            .getPopupSubmissionList,
            decodeTo: [PopupSubmissionDTO].self
        )
        .map { $0.toEntity() }
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await adminProvider.asyncRequestVoid(.createPopupSubmission(requestDTO: request.toDTO()))
    }

    public func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(.deactivatePopupByUser(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func deactivatePopup(popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(.deactivatePopup(popupUuid: popupUuid))
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
