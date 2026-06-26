import Domain
import Foundation

extension PopupSubmissionAdminListResponseDTO {
    func toEntity() throws -> PopupSubmissionListItem {
        guard let status = PopupSubmissionStatus(rawValue: status) else {
            throw PopupSubmissionMappingError.unknownStatus(status)
        }

        return PopupSubmissionListItem(
            id: popupSubmissionId,
            name: name,
            roadAddress: roadAddress,
            region: region,
            submitterUserUuid: submitterUserUuid,
            submitterNickname: submitterNickname,
            submittedAt: submittedAt,
            status: status
        )
    }
}
