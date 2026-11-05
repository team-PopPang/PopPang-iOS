//
//  PopupDetailClient.swift
//  PopupDetailFeature
//
//  Created by 김동현 on 7/1/26.
//

import ComposableArchitecture
import Domain

public struct PopupDetailClient: Sendable {
    /// 상세 데이터를 받는다. 없는 팝업이면 `PopupError.notFound`를 던진다.
    var getPopupDetail: @Sendable (_ popupUuid: String) async throws -> PopupDetail
    var increaseViewCount: @Sendable (_ popupUuid: String) async throws -> Void
    var getRelatedPopupList: @Sendable (_ popupUuid: String) async throws -> [Popup]
    var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    var deactivatePopup: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getPopupDetail: @escaping @Sendable (_ popupUuid: String) async throws -> PopupDetail,
        increaseViewCount: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        getRelatedPopupList: @escaping @Sendable (_ popupUuid: String) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        deactivatePopup: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getPopupDetail = getPopupDetail
        self.increaseViewCount = increaseViewCount
        self.getRelatedPopupList = getRelatedPopupList
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
            getPopupDetail: { popupUuid in
                try await popupUsecaseBox.usecase.getPopupDetail(popupUuid: popupUuid)
            },
            increaseViewCount: { popupUuid in
                try await popupUsecaseBox.usecase.increaseViewCount(popupUuid: popupUuid)
            },
            getRelatedPopupList: { popupUuid in
                try await popupUsecaseBox.usecase.getRelatedPopupList(popupUuid: popupUuid)
            },
            addFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(popupUuid: popupUuid)
            },
            removeFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(popupUuid: popupUuid)
            },
            deactivatePopup: { popupUuid in
                try await adminUsecaseBox.usecase.deactivatePopup(popupUuid: popupUuid)
            }
        )
    }
}

extension PopupDetailClient: DependencyKey {
    public static let liveValue = PopupDetailClient(
        getPopupDetail: { _ in throw PopupError.failed },
        increaseViewCount: { _ in },
        getRelatedPopupList: { _ in [] },
        addFavorite: { _ in },
        removeFavorite: { _ in },
        deactivatePopup: { _ in }
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
