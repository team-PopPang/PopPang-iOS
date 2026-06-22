import Foundation

public struct PopupSubmission: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let startDate: String
    public let endDate: String
    public let address: String
    public let description: String
    public let status: PopupSubmissionStatus
    public let createdAt: String

    public init(
        id: Int,
        name: String,
        startDate: String,
        endDate: String,
        address: String,
        description: String,
        status: PopupSubmissionStatus,
        createdAt: String
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.address = address
        self.description = description
        self.status = status
        self.createdAt = createdAt
    }
}
