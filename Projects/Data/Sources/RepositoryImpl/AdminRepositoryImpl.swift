import Core
import Domain
import Foundation
import Moya

public final class AdminRepositoryImpl: AdminRepositoryProtocol {
    public init() {}

    public func getPopupValidationList() async throws -> Data {
        try await adminProvider.asyncRequest(.getPopupValidationList).data
    }

    public func validatePopup(parameters: [String: Any]) async throws {
        try await adminProvider.asyncRequestVoid(.validatePopup(parameters: parameters))
    }

    public func registerPopup(parameters: [String: Any]) async throws -> String? {
        let response = try await adminProvider.asyncRequest(.registerPopup(parameters: parameters))
        guard response.data.isEmpty == false else { return nil }
        return try JSONDecoder().decode(AdminPopupRegistrationResponseDTO.self, from: response.data).popupUuid
    }

    public func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws {
        try await adminProvider.asyncRequestVoid(.createPopupSubmission(requestDTO: request.toDTO()))
    }

    public func registerPopupRecommendations(popupUuid: String, recommendIds: [Int]) async throws {
        try await adminProvider.asyncRequestVoid(
            .registerPopupRecommendations(popupUuid: popupUuid, recommendIds: recommendIds)
        )
    }

    public func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid))
    }

    private var adminProvider: MoyaProvider<AdminAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
