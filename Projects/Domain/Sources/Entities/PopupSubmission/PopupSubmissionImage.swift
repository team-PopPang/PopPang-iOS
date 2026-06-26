import Foundation

public struct PopupSubmissionImage: Equatable, Sendable {
    public let imageUrl: String
    public let sortOrder: Int

    public init(
        imageUrl: String,
        sortOrder: Int
    ) {
        self.imageUrl = imageUrl
        self.sortOrder = sortOrder
    }
}
