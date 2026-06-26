import Domain
import Foundation

extension PopupSubmissionImageRequestDTO {
    func toEntity() -> PopupSubmissionImage {
        PopupSubmissionImage(
            imageUrl: imageUrl,
            sortOrder: sortOrder
        )
    }
}

extension PopupSubmissionImage {
    func toDTO() -> PopupSubmissionImageRequestDTO {
        PopupSubmissionImageRequestDTO(
            imageUrl: imageUrl,
            sortOrder: sortOrder
        )
    }
}
