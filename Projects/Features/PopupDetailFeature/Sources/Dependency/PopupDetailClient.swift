//
//  PopupDetailClient.swift
//  PopupDetailFeature
//
//  Created by 김동현 on 7/1/26.
//

import ComposableArchitecture
import Domain

public struct PopupDetailClient: Sendable {
    var increaseViewCount: @Sendable (_ popupUuid: String) async throws -> Void
    var getPersonalRelatedPopupList: @Sendable (
        _ userUuid: String,
        _ popupUuid: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var deactivatePopup: @Sendable (_ adminUuid: String, _ popupUuid: String) async throws -> Void

    public init(
        increaseViewCount: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        getPersonalRelatedPopupList: @escaping @Sendable (
            _ userUuid: String,
            _ popupUuid: String
        ) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void,
        deactivatePopup: @escaping @Sendable (_ adminUuid: String, _ popupUuid: String) async throws -> Void
    ) {
        self.increaseViewCount = increaseViewCount
        self.getPersonalRelatedPopupList = getPersonalRelatedPopupList
        self.addFavorite = addFavorite
        self.removeFavorite = removeFavorite
        self.deactivatePopup = deactivatePopup
    }
}

extension PopupDetailClient {
    public static func live(
        popupUsecase: PopupUsecaseProtocol,
        adminUsecase: AdminUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupDetailPopupUsecaseBox(popupUsecase)
        let adminUsecaseBox = PopupDetailAdminUsecaseBox(adminUsecase)

        return Self(
            increaseViewCount: { popupUuid in
                try await popupUsecaseBox.usecase.increaseViewCount(popupUuid: popupUuid)
            },
            getPersonalRelatedPopupList: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.getPersonalRelatedPopupList(
                    userUuid: userUuid,
                    popupUuid: popupUuid
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            deactivatePopup: { adminUuid, popupUuid in
                try await adminUsecaseBox.usecase.deactivatePopup(
                    adminUuid: adminUuid,
                    popupUuid: popupUuid
                )
            }
        )
    }
}

extension PopupDetailClient: DependencyKey {
    public static let liveValue = PopupDetailClient(
        increaseViewCount: { _ in },
        getPersonalRelatedPopupList: { _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in },
        deactivatePopup: { _, _ in }
    )
}

extension DependencyValues {
    public var popupDetailClient: PopupDetailClient {
        get { self[PopupDetailClient.self] }
        set { self[PopupDetailClient.self] = newValue }
    }
}

private final class PopupDetailPopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class PopupDetailAdminUsecaseBox: @unchecked Sendable {
    let usecase: AdminUsecaseProtocol

    init(_ usecase: AdminUsecaseProtocol) {
        self.usecase = usecase
    }
}
