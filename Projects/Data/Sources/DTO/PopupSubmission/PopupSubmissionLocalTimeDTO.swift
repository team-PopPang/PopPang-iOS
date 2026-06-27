import Foundation

public struct PopupSubmissionLocalTimeDTO: Codable, Equatable, Sendable {
    public let hour: Int
    public let minute: Int
    public let second: Int
    public let nano: Int

    public init(
        hour: Int,
        minute: Int,
        second: Int,
        nano: Int
    ) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nano = nano
    }
}
