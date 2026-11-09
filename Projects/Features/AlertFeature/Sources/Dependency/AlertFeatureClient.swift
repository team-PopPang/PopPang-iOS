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

/// 알림 화면이 쓰는 요청. 모두 Access Token의 사용자로 처리하는 V2 API라 `userUuid`를 받지 않는다.
public struct AlertFeatureClient: Sendable {
    public var getAlertPopupList: @Sendable () async throws -> [Popup]
    public var removeAlertPopup: @Sendable (_ popupUuid: String) async throws -> Void
    public var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var getAlertKeywordList: @Sendable () async throws -> [Keyword]
    public var addAlertKeyword: @Sendable (_ keyword: String) async throws -> Void
    public var removeAlertKeyword: @Sendable (_ keyword: String) async throws -> Void
    public var loadRecentKeywords: @Sendable () -> [String]
    public var removeRecentKeyword: @Sendable (String) -> Void

    public init(
        getAlertPopupList: @escaping @Sendable () async throws -> [Popup],
        removeAlertPopup: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        getAlertKeywordList: @escaping @Sendable () async throws -> [Keyword],
        addAlertKeyword: @escaping @Sendable (_ keyword: String) async throws -> Void,
        removeAlertKeyword: @escaping @Sendable (_ keyword: String) async throws -> Void,
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
            getAlertPopupList: {
                try await popupUsecaseBox.usecase.getAlertPopupList()
            },
            removeAlertPopup: { popupUuid in
                try await popupUsecaseBox.usecase.removeAlertPopup(popupUuid: popupUuid)
            },
            addFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(popupUuid: popupUuid)
            },
            removeFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(popupUuid: popupUuid)
            },
            getAlertKeywordList: {
                try await userUsecaseBox.usecase.getAlertKeywordList()
            },
            addAlertKeyword: { keyword in
                try await userUsecaseBox.usecase.addAlertKeyword(alertKeyword: keyword)
            },
            removeAlertKeyword: { keyword in
                try await userUsecaseBox.usecase.removeAlertKeyword(alertKeyword: keyword)
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
        getAlertPopupList: { throw AlertFeatureUnimplementedError() },
        removeAlertPopup: { _ in throw AlertFeatureUnimplementedError() },
        addFavorite: { _ in throw AlertFeatureUnimplementedError() },
        removeFavorite: { _ in throw AlertFeatureUnimplementedError() },
        getAlertKeywordList: { throw AlertFeatureUnimplementedError() },
        addAlertKeyword: { _ in throw AlertFeatureUnimplementedError() },
        removeAlertKeyword: { _ in throw AlertFeatureUnimplementedError() },
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
