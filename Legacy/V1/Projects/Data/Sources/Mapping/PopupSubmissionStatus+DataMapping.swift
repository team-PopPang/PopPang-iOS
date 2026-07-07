import Domain

extension PopupSubmissionStatus {
    func toDTO() -> PopupSubmissionStatusUpdateRequestDTO {
        PopupSubmissionStatusUpdateRequestDTO(popupSubmissionStatus: rawValue)
    }
}
