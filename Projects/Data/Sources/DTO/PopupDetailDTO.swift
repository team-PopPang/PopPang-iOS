import Core
import Domain
import Foundation

/// 팝업 단건 조회(`GET /api/v2/user/popups/{popupUuid}`) 응답
///
/// 지금은 목록의 `PopupDTO`와 같은 키에 `isFavorited`가 있다. 상세 전용 값이 생기면 여기에 더한다.
/// null일 수 있는 값은 `PopupDTO`와 같은 기준으로 바꾼다.
public struct PopupDetailDTO: Decodable, Sendable {
    public let popupUuid: String
    public let name: String
    public let startDate: String
    public let endDate: String
    public let openTime: String?
    public let closeTime: String?
    public let address: String
    public let roadAddress: String?
    public let region: String
    public let latitude: Double?
    public let longitude: Double?
    public let instaPostId: String?
    public let instaPostUrl: String?
    public let captionSummary: String
    public let imageUrlList: [String]
    public let mediaType: String?
    public let favoriteCount: Int
    public let viewCount: Int
    public let isFavorited: Bool
    public let recommendList: [String]?
}

public extension PopupDetailDTO {
    func toEntity() -> PopupDetail {
        PopupDetail(
            popupUuid: popupUuid,
            name: name,
            startDate: DateFormatter.popupDateFormat.date(from: startDate) ?? Date(),
            endDate: DateFormatter.popupDateFormat.date(from: endDate) ?? Date(),
            openTime: openTime,
            closeTime: closeTime,
            address: address,
            roadAddress: PopupFieldMapping.roadAddress(roadAddress, fallback: address),
            region: region,
            latitude: latitude,
            longitude: longitude,
            instaPostId: instaPostId,
            instaPostUrl: instaPostUrl,
            captionSummary: captionSummary,
            imageUrlList: PopupFieldMapping.imageUrlList(imageUrlList),
            mediaType: PopupFieldMapping.mediaType(mediaType),
            favoriteCount: favoriteCount,
            viewCount: viewCount,
            isFavorited: isFavorited,
            recommendList: recommendList ?? []
        )
    }
}
