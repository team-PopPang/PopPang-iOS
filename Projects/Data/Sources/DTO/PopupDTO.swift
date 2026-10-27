import Core
import Domain
import Foundation

public struct PopupDTO: Decodable, Sendable {
    public let popupUuid: String
    public let name: String
    public let startDate: String
    public let endDate: String
    public let openTime: String?
    public let closeTime: String?
    public let address: String
    /// 명세상 null일 수 있다. 없으면 빈 문자열로 바꾼다.
    public let roadAddress: String?
    public let region: String
    public let latitude: Double?
    public let longitude: Double?
    public let instaPostId: String?
    public let instaPostUrl: String?
    public let captionSummary: String
    public let imageUrlList: [String]
    /// 명세상 null일 수 있다. 없으면 이미지로 본다.
    public let mediaType: String?
    public let favoriteCount: Int
    public let viewCount: Int
    public let isFavorited: Bool
    /// 명세상 목록 API는 추천이 없으면 null을 준다. 없으면 빈 배열로 바꾼다.
    public let recommendList: [String]?
}

public extension PopupDTO {
    func toEntity() -> Popup {
        let fullImageUrlList = imageUrlList.map { url in
            if url.hasPrefix("http") {
                return url
            } else {
                return Constants.PopPangAPI.imageURL + url
            }
        }

        return Popup(
            popupUuid: popupUuid,
            name: name,
            startDate: DateFormatter.popupDateFormat.date(from: startDate) ?? Date(),
            endDate: DateFormatter.popupDateFormat.date(from: endDate) ?? Date(),
            openTime: openTime,
            closeTime: closeTime,
            address: address,
            roadAddress: roadAddress ?? "",
            region: region,
            latitude: latitude,
            longitude: longitude,
            instaPostId: instaPostId,
            instaPostUrl: instaPostUrl,
            captionSummary: captionSummary,
            imageUrlList: fullImageUrlList,
            mediaType: mediaType.flatMap { Popup.MediaType(rawValue: $0.uppercased()) } ?? .image,
            favoriteCount: favoriteCount,
            viewCount: viewCount,
            isFavorited: isFavorited,
            recommendList: recommendList ?? []
        )
    }
}
