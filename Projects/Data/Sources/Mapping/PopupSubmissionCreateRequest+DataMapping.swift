import Domain
import Foundation

extension PopupSubmissionCreateRequest {
    func toDTO() -> PopupSubmissionCreateRequestDTO {
        PopupSubmissionCreateRequestDTO(
            name: name,
            startDate: DateFormatter.popupSubmissionDateFormat.string(from: startDate),
            endDate: DateFormatter.popupSubmissionDateFormat.string(from: endDate),
            address: address,
            description: description,
            submitterUserId: submitterUserId
        )
    }
}

private extension DateFormatter {
    static let popupSubmissionDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
