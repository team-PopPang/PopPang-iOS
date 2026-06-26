import Foundation

public struct PopupSubmissionLocalTime: Equatable, Sendable {
    public let hour: Int
    public let minute: Int
    public let second: Int
    public let nano: Int

    public init(
        hour: Int,
        minute: Int,
        second: Int = 0,
        nano: Int = 0
    ) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nano = nano
    }
}
