import Foundation

public struct PopupSubmissionCreateRequestDTO: Encodable, Sendable {
    public let userUuid: String
    public let name: String
    public let startDate: String
    public let endDate: String
    public let openTime: PopupSubmissionLocalTimeDTO?
    public let closeTime: PopupSubmissionLocalTimeDTO?
    public let address: String
    public let roadAddress: String
    public let region: String
    public let instaPostUrl: String?
    public let description: String
    public let imageList: [PopupSubmissionImageRequestDTO]
    public let recommendIdList: [Int]

    public init(
        userUuid: String,
        name: String,
        startDate: String,
        endDate: String,
        openTime: PopupSubmissionLocalTimeDTO?,
        closeTime: PopupSubmissionLocalTimeDTO?,
        address: String,
        roadAddress: String,
        region: String,
        instaPostUrl: String?,
        description: String,
        imageList: [PopupSubmissionImageRequestDTO],
        recommendIdList: [Int]
    ) {
        self.userUuid = userUuid
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.openTime = openTime
        self.closeTime = closeTime
        self.address = address
        self.roadAddress = roadAddress
        self.region = region
        self.instaPostUrl = instaPostUrl
        self.description = description
        self.imageList = imageList
        self.recommendIdList = recommendIdList
    }
}
