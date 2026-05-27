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
    public let roadAddress: String
    public let region: String
    public let latitude: Double?
    public let longitude: Double?
    public let instaPostId: String
    public let instaPostUrl: String
    public let captionSummary: String
    public let imageUrlList: [String]
    public let mediaType: String
    public let favoriteCount: Int
    public let viewCount: Int
    public let isFavorited: Bool
    public let recommendList: [String]
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
            roadAddress: roadAddress,
            region: region,
            latitude: latitude,
            longitude: longitude,
            instaPostId: instaPostId,
            instaPostUrl: instaPostUrl,
            captionSummary: captionSummary,
            imageUrlList: fullImageUrlList,
            mediaType: Popup.MediaType(rawValue: mediaType.uppercased()) ?? .image,
            favoriteCount: favoriteCount,
            viewCount: viewCount,
            isFavorited: isFavorited,
            recommendList: recommendList
        )
    }
}
