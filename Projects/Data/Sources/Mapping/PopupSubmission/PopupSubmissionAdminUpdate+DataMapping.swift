import Domain
import Foundation

extension PopupSubmissionAdminUpdateRequest {
    func toDTO() -> PopupSubmissionAdminUpdateRequestDTO {
        PopupSubmissionAdminUpdateRequestDTO(
            status: status.rawValue,
            name: name,
            startDate: startDate.map { popupSubmissionDateFormatter.string(from: $0) },
            endDate: endDate.map { popupSubmissionDateFormatter.string(from: $0) },
            roadAddress: roadAddress,
            region: region,
            address: address,
            openTime: openTime?.toDTO(),
            closeTime: closeTime?.toDTO(),
            latitude: latitude,
            longitude: longitude,
            captionSummary: captionSummary,
            caption: caption,
            mediaType: mediaType?.rawValue,
            instaPostUrl: instaPostUrl,
            instaPostId: instaPostId,
            geocodingQuery: geocodingQuery,
            imageList: imageList.map { $0.toDTO() },
            recommendIdList: recommendIdList,
            isActive: isActive
        )
    }
}

extension PopupSubmissionAdminUpdateResponseDTO {
    func toEntity() -> PopupSubmissionAdminUpdateResult {
        PopupSubmissionAdminUpdateResult(popupUuid: popupUuid)
    }
}
