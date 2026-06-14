import Foundation

public struct PopupSubmissionDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let startDate: String
    public let endDate: String
    public let address: String
    public let description: String
    public let status: String
    public let createdAt: String
}
