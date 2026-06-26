import Foundation

public struct PopupSubmissionAdminListResponseDTO: Decodable, Sendable {
    public let popupSubmissionId: Int
    public let name: String
    public let roadAddress: String
    public let region: String
    public let submitterUserUuid: String
    public let submitterNickname: String
    public let submittedAt: String
    public let status: String
}
