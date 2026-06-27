import Domain
import Foundation

public struct PopupRequestManagementListItem: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let roadAddress: String
    public let region: String
    public let submitterNickname: String
    public let submittedAtText: String
    public let status: PopupSubmissionStatus

    init(item: PopupSubmissionListItem) {
        self.id = item.id
        self.name = item.name
        self.roadAddress = item.roadAddress
        self.region = item.region
        self.submitterNickname = item.submitterNickname
        self.submittedAtText = item.submittedAt.split(separator: "T").first.map(String.init) ?? item.submittedAt
        self.status = item.status
    }
}
