import Foundation

public struct PopupSubmissionListItem: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let roadAddress: String
    public let region: String
    public let submitterUserUuid: String
    public let submitterNickname: String
    public let submittedAt: String
    public let status: PopupSubmissionStatus

    public init(
        id: Int,
        name: String,
        roadAddress: String,
        region: String,
        submitterUserUuid: String,
        submitterNickname: String,
        submittedAt: String,
        status: PopupSubmissionStatus
    ) {
        self.id = id
        self.name = name
        self.roadAddress = roadAddress
        self.region = region
        self.submitterUserUuid = submitterUserUuid
        self.submitterNickname = submitterNickname
        self.submittedAt = submittedAt
        self.status = status
    }
}
