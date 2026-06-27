import Foundation

public enum PopupSubmissionListFilter: String, CaseIterable, Equatable, Sendable {
    case all = "전체"
    case pending = "대기"
    case approved = "승인"
    case rejected = "반려"
}
