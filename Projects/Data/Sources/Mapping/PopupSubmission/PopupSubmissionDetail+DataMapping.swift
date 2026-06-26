import Domain
import Foundation

extension PopupSubmissionRecommendResponseDTO {
    func toEntity() -> Recommend {
        Recommend(id: recommendId, recommendName: recommendName)
    }
}

extension PopupSubmissionAdminDetailResponseDTO {
    func toEntity() throws -> PopupSubmissionDetail {
        guard let status = PopupSubmissionStatus(rawValue: status) else {
            throw PopupSubmissionMappingError.unknownStatus(status)
        }

        return PopupSubmissionDetail(
            id: popupSubmissionId,
            name: name,
            startDate: try popupSubmissionDateFormatter.dateStringToDate(startDate),
            endDate: try popupSubmissionDateFormatter.dateStringToDate(endDate),
            roadAddress: roadAddress,
            region: region,
            description: description,
            recommendIdList: recommendIdList,
            recommendList: recommendList.map { $0.toEntity() },
            imageList: imageList.map { $0.toEntity() },
            address: address,
            openTime: openTime?.toEntity(),
            closeTime: closeTime?.toEntity(),
            instaPostUrl: instaPostUrl,
            status: status
        )
    }
}
