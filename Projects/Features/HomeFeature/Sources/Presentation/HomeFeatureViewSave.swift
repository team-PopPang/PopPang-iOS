import Core
import Domain
import SwiftUI

public struct HomeFeatureViewSave: View {
    private let userUuid: String
    private let nickname: String
    private let deepLinkStorage: DeepLinkStorage
    private let onSelectPopup: (String, Popup) -> Void
    private let onShowAlert: (String) -> Void
    private let onSearch: (String) -> Void
    private let onShowComingPopups: (String, [Popup]) -> Void

    public init(
        userUuid: String = "demo-user",
        nickname: String = "닉네임",
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore()),
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onShowAlert: @escaping (String) -> Void = { _ in },
        onSearch: @escaping (String) -> Void = { _ in },
        onShowComingPopups: @escaping (String, [Popup]) -> Void = { _, _ in }
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.deepLinkStorage = deepLinkStorage
        self.onSelectPopup = onSelectPopup
        self.onShowAlert = onShowAlert
        self.onSearch = onSearch
        self.onShowComingPopups = onShowComingPopups
    }

    public var body: some View {
        HomeFeatureView(
            userUuid: userUuid,
            nickname: nickname,
            deepLinkStorage: deepLinkStorage,
            onSelectPopup: onSelectPopup,
            onShowAlert: onShowAlert,
            onSearch: onSearch,
            onShowComingPopups: onShowComingPopups
        )
    }
}

public struct ComingPopupDetailFeatureViewSave: View {
    private let userUuid: String
    private let popups: [Popup]
    private let onSelectPopup: (String, Popup) -> Void

    public init(
        userUuid: String,
        popups: [Popup],
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
    ) {
        self.userUuid = userUuid
        self.popups = popups
        self.onSelectPopup = onSelectPopup
    }

    public var body: some View {
        ComingPopupDetailFeatureView(
            userUuid: userUuid,
            popups: popups,
            onSelectPopup: onSelectPopup
        )
    }
}
