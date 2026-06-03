import Foundation

public struct PopupSubmissionCreateRequest: Equatable, Sendable {
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let address: String
    public let description: String
    public let submitterUserId: Int64?

    public init(
        name: String,
        startDate: Date,
        endDate: Date,
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
