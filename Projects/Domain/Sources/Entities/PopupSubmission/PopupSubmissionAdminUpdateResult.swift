import Foundation

public struct PopupSubmissionAdminUpdateResult: Equatable, Sendable {
    public let popupUuid: String?

    public init(popupUuid: String?) {
        self.popupUuid = popupUuid
    }
}
