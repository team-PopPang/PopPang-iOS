import Foundation

public struct PopupSubmissionCreateRequestDTO: Encodable, Sendable {
    public let name: String
    public let startDate: String
    public let endDate: String
    public let address: String
    public let description: String
    public let submitterUserId: Int64?

    public init(
        name: String,
        startDate: String,
        endDate: String,
        address: String,
        description: String,
        submitterUserId: Int64?
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.address = address
        self.description = description
        self.submitterUserId = submitterUserId
    }
}
