import Foundation

/// 팝업 상세 화면이 보여 주는 데이터
///
/// 목록용 `Popup`과 따로 둔다. 상세 전용 데이터(예: 리뷰, 운영 정보)가 붙어도 목록 모델은 바뀌지 않는다.
/// 지금은 단건 조회 응답의 값이 `Popup`과 같다.
public struct PopupDetail: Hashable, Identifiable, Sendable {
    public var id: String { popupUuid }

    public let popupUuid: String
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let openTime: String?
    public let closeTime: String?
    public let address: String
    /// 도로명 주소. 없거나 비어 있으면 일반 주소다.
    public let roadAddress: String
    public let region: String
    public let latitude: Double?
    public let longitude: Double?
    public let instaPostId: String?
    public let instaPostUrl: String?
    public let captionSummary: String
    public let imageUrlList: [String]
    public let mediaType: Popup.MediaType
    public var favoriteCount: Int
    public var viewCount: Int
    public var isFavorited: Bool
    public let recommendList: [String]

    public init(
        popupUuid: String,
        name: String,
        startDate: Date,
        endDate: Date,
        openTime: String?,
        closeTime: String?,
        address: String,
        roadAddress: String,
        region: String,
        latitude: Double?,
        longitude: Double?,
        instaPostId: String?,
        instaPostUrl: String?,
        captionSummary: String,
        imageUrlList: [String],
        mediaType: Popup.MediaType,
        favoriteCount: Int,
        viewCount: Int,
        isFavorited: Bool,
        recommendList: [String]
    ) {
        self.popupUuid = popupUuid
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.openTime = openTime
        self.closeTime = closeTime
        self.address = address
        self.roadAddress = roadAddress
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
        self.instaPostId = instaPostId
        self.instaPostUrl = instaPostUrl
        self.captionSummary = captionSummary
        self.imageUrlList = imageUrlList
        self.mediaType = mediaType
        self.favoriteCount = favoriteCount
        self.viewCount = viewCount
        self.isFavorited = isFavorited
        self.recommendList = recommendList
    }
}
