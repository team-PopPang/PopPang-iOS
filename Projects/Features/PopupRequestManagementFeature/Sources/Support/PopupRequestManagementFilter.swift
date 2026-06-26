import Domain
import Foundation

public enum PopupRequestManagementFilter: CaseIterable, Equatable, Sendable {
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

    var domainFilter: PopupSubmissionListFilter {
        switch self {
        case .all:
            .all
        case .pending:
            .pending
        case .approved:
            .approved
        case .rejected:
            .rejected
        }
    }

    var status: PopupSubmissionStatus? {
        switch self {
        case .all:
            nil
        case .pending:
            .pending
        case .approved:
            .approved
        case .rejected:
            .rejected
        }
    }
}
