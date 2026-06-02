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

    public func registerPopup(parameters: [String: Any]) async throws {
        try await adminProvider.asyncRequestVoid(.registerPopup(parameters: parameters))
    }

    public func uploadPopupImages(popupUuid: String, images: [AdminPopupImageUploadItem]) async throws {
        let multipartFormData = images.map { $0.toDTO().toMultipartFormData() }
        try await adminProvider.asyncRequestVoid(
            .uploadPopupImages(popupUuid: popupUuid, multipartFormData: multipartFormData)
        )
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
