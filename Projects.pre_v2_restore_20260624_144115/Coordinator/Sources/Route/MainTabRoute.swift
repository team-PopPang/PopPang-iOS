import Domain

public enum MainTabRoute: Identifiable, Hashable, Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case comingPopupDetail(userUuid: String, popups: [Popup])
    case reviewDetail([Review])
    case alert(userUuid: String)
    case popupRequest(userUuid: String)
    case popupRequestManagement
    case popupRequestManagementDetail(submissionId: String)
    case profileSetting(userUuid: String, nickname: String, isAlerted: Bool)
    case notifications
    case serviceTerms

    public var id: String {
        switch self {
        case .popupDetail(let userUuid, let popup):
            "popupDetail-\(userUuid)-\(popup.popupUuid)"
        case .comingPopupDetail(let userUuid, let popups):
            "comingPopupDetail-\(userUuid)-\(popups.map(\.popupUuid).joined(separator: "-"))"
        case .reviewDetail(let reviews):
            "reviewDetail-\(reviews.map(\.id.uuidString).joined(separator: "-"))"
        case .alert(let userUuid):
            "alert-\(userUuid)"
        case .popupRequest(let userUuid):
            "popupRequest-\(userUuid)"
        case .popupRequestManagement:
            "popupRequestManagement"
        case .popupRequestManagementDetail(let submissionId):
            "popupRequestManagementDetail-\(submissionId)"
        case .profileSetting(let userUuid, let nickname, let isAlerted):
            "profileSetting-\(userUuid)-\(nickname)-\(isAlerted)"
        case .notifications:
            "notifications"
        case .serviceTerms:
            "serviceTerms"
        }
    }
}

public enum MainTabFullScreenRoute: Identifiable, Hashable, Sendable {
    case search(userUuid: String)

    public var id: String {
        switch self {
        case .search(let userUuid):
            "search-\(userUuid)"
        }
    }

    public var isPresentationAnimated: Bool {
        switch self {
        case .search:
            false
        }
    }
}

public struct MainTabSession: Equatable, Hashable, Sendable {
    public var userUuid: String
    public var nickname: String
    public var isAlerted: Bool
    public var role: String

    public init(
        userUuid: String,
        nickname: String = "닉네임",
        isAlerted: Bool = false,
        role: String = "USER"
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.role = role
    }

    public var isAdmin: Bool {
        role.uppercased() == "ADMIN"
    }
}
