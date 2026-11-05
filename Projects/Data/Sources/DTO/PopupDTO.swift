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
    /// 명세상 null일 수 있다. 없거나 비어 있으면 일반 주소(`address`)를 대신 쓴다.
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
        Popup(
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

/// 목록(`PopupDTO`)과 상세(`PopupDetailDTO`)가 같은 기준으로 값을 바꾸도록 모은다.
enum PopupFieldMapping {
    /// 상대 경로 이미지는 이미지 서버 주소를 붙인다.
    static func imageUrlList(_ urls: [String]) -> [String] {
        urls.map { url in
            url.hasPrefix("http") ? url : Constants.PopPangAPI.imageURL + url
        }
    }

    /// 도로명 주소가 없거나 비어 있으면 일반 주소를 쓴다.
    static func roadAddress(_ roadAddress: String?, fallback address: String) -> String {
        roadAddress.flatMap { $0.isEmpty ? nil : $0 } ?? address
    }

    /// 미디어 종류가 없거나 모르는 값이면 이미지로 본다.
    static func mediaType(_ mediaType: String?) -> Popup.MediaType {
        mediaType.flatMap { Popup.MediaType(rawValue: $0.uppercased()) } ?? .image
    }
}
