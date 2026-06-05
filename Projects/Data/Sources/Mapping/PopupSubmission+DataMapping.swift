import Domain
import Foundation

extension PopupSubmissionDTO {
    func toEntity() -> PopupSubmission {
        PopupSubmission(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            address: address,
            description: description,
            status: PopupSubmissionStatus(rawValue: status) ?? .pending,
            createdAt: createdAt
        )
    }
}
