import Domain
import Foundation

public enum PopupRequestManagementStatus: String, CaseIterable, Hashable, Sendable {
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .pending:
            "검토 대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }

    init(status: PopupSubmissionStatus) {
        switch status {
        case .pending:
            self = .pending
        case .approved:
            self = .approved
        case .rejected:
            self = .rejected
        }
    }
}

public enum PopupRequestManagementFilter: CaseIterable, Hashable, Sendable {
    case all
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .all:
            "전체"
        case .pending:
            "대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }
}

public struct PopupRequestManagementItem: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let popupName: String
    public let region: String
    public let address: String
    public let periodText: String
    public let description: String
    public let submittedAtText: String
    public let submitterNickname: String
    public let status: PopupRequestManagementStatus

    public init(
        id: String,
        popupName: String,
        region: String,
        address: String,
        periodText: String = "",
        description: String = "",
        submittedAtText: String,
        submitterNickname: String,
        status: PopupRequestManagementStatus
    ) {
        self.id = id
        self.popupName = popupName
        self.region = region
        self.address = address
        self.periodText = periodText
        self.description = description
        self.submittedAtText = submittedAtText
        self.submitterNickname = submitterNickname
        self.status = status
    }
}

public extension PopupRequestManagementItem {
    static let mock = PopupRequestManagementItem(
        id: "submission-1",
        popupName: "임시 팝업 제보",
        region: "서울",
        address: "서울시 성동구",
        periodText: "2026.06.01 - 2026.06.30",
        description: "코디네이터 재구성 전 임시 제보 데이터입니다.",
        submittedAtText: "2026.06.23",
        submitterNickname: "테스터",
        status: .pending
    )
}
