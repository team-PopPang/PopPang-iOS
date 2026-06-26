import Foundation

public struct PopupSubmissionImageItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var imageUrl: String

    public init(
        id: UUID = UUID(),
        imageUrl: String = ""
    ) {
        self.id = id
        self.imageUrl = imageUrl
    }
}
