//
//  AlertFeatureClient.swift
//  AlertFeature
//
//  Created by 김동현 on 7/3/26.
//

import ComposableArchitecture
import Core
import Domain
import Foundation

public struct AlertFeatureClient: Sendable {
    public var getAlertPopupList: @Sendable (String) async throws -> [Popup]
    public var removeAlertPopup: @Sendable (String, String) async throws -> Void
    public var addFavorite: @Sendable (String, String) async throws -> Void
    public var removeFavorite: @Sendable (String, String) async throws -> Void
    public var getAlertKeywordList: @Sendable (String) async throws -> [Keyword]
    public var addAlertKeyword: @Sendable (String, String) async throws -> Void
    public var removeAlertKeyword: @Sendable (String, String) async throws -> Void
    public var loadRecentKeywords: @Sendable () -> [String]
    public var removeRecentKeyword: @Sendable (String) -> Void

    public init(
        getAlertPopupList: @escaping @Sendable (String) async throws -> [Popup],
        removeAlertPopup: @escaping @Sendable (String, String) async throws -> Void,
        addFavorite: @escaping @Sendable (String, String) async throws -> Void,
        removeFavorite: @escaping @Sendable (String, String) async throws -> Void,
        getAlertKeywordList: @escaping @Sendable (String) async throws -> [Keyword],
        addAlertKeyword: @escaping @Sendable (String, String) async throws -> Void,
        removeAlertKeyword: @escaping @Sendable (String, String) async throws -> Void,
        loadRecentKeywords: @escaping @Sendable () -> [String],
        removeRecentKeyword: @escaping @Sendable (String) -> Void
    ) {
        self.getAlertPopupList = getAlertPopupList
        self.removeAlertPopup = removeAlertPopup
        self.addFavorite = addFavorite
        self.removeFavorite = removeFavorite
        self.getAlertKeywordList = getAlertKeywordList
        self.addAlertKeyword = addAlertKeyword
        self.removeAlertKeyword = removeAlertKeyword
        self.loadRecentKeywords = loadRecentKeywords
        self.removeRecentKeyword = removeRecentKeyword
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol,
        userUsecase: UserUsecaseProtocol,
        recentSearchStorage: RecentSearchStorage
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)
        let userUsecaseBox = UserUsecaseBox(userUsecase)

        return Self(
            getAlertPopupList: { userUuid in
                try await popupUsecaseBox.usecase.getAlertPopupList(userUuid: userUuid)
            },
            removeAlertPopup: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.removeAlertPopup(
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
            getAlertKeywordList: { userUuid in
                try await userUsecaseBox.usecase.getAlertKeywordList(userUuid: userUuid)
            },
            addAlertKeyword: { userUuid, keyword in
                try await userUsecaseBox.usecase.addAlertKeyword(
                    userUuid: userUuid,
                    alertKeyword: keyword
                )
            },
            removeAlertKeyword: { userUuid, keyword in
                try await userUsecaseBox.usecase.removeAlertKeyword(
                    userUuid: userUuid,
                    alertKeyword: keyword
                )
            },
            loadRecentKeywords: {
                recentSearchStorage.load()
            },
            removeRecentKeyword: { keyword in
                recentSearchStorage.remove(keyword)
            }
        )
    }
}

private struct AlertFeatureUnimplementedError: Error {}

extension AlertFeatureClient {
    public static let unimplemented = Self(
        getAlertPopupList: { _ in throw AlertFeatureUnimplementedError() },
        removeAlertPopup: { _, _ in throw AlertFeatureUnimplementedError() },
        addFavorite: { _, _ in throw AlertFeatureUnimplementedError() },
        removeFavorite: { _, _ in throw AlertFeatureUnimplementedError() },
        getAlertKeywordList: { _ in throw AlertFeatureUnimplementedError() },
        addAlertKeyword: { _, _ in throw AlertFeatureUnimplementedError() },
        removeAlertKeyword: { _, _ in throw AlertFeatureUnimplementedError() },
        loadRecentKeywords: { [] },
        removeRecentKeyword: { _ in }
    )
}

extension AlertFeatureClient: DependencyKey {
    public static let liveValue = Self.unimplemented
}

extension AlertFeatureClient: TestDependencyKey {
    public static let testValue = Self.unimplemented
}

extension DependencyValues {
    public var alertFeatureClient: AlertFeatureClient {
        get { self[AlertFeatureClient.self] }
        set { self[AlertFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class UserUsecaseBox: @unchecked Sendable {
    let usecase: UserUsecaseProtocol

    init(_ usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
}
