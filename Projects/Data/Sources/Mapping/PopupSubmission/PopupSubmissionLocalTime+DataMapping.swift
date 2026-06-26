import Domain
import Foundation

extension PopupSubmissionLocalTimeDTO {
    func toEntity() -> PopupSubmissionLocalTime {
        PopupSubmissionLocalTime(
            hour: hour,
            minute: minute,
            second: second,
            nano: nano
        )
    }
}

extension PopupSubmissionLocalTime {
    func toDTO() -> PopupSubmissionLocalTimeDTO {
        PopupSubmissionLocalTimeDTO(
            hour: hour,
            minute: minute,
            second: second,
            nano: nano
        )
    }
}
