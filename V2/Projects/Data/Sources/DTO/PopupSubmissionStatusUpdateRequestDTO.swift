public struct PopupSubmissionStatusUpdateRequestDTO: Encodable, Sendable {
    public let popupSubmissionStatus: String

    public init(popupSubmissionStatus: String) {
        self.popupSubmissionStatus = popupSubmissionStatus
    }
}
