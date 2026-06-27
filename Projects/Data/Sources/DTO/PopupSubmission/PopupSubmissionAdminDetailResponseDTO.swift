import Foundation

public struct PopupSubmissionAdminDetailResponseDTO: Decodable, Sendable {
    public let popupSubmissionId: Int
    public let name: String
    public let startDate: String
    public let endDate: String
    public let roadAddress: String
    public let region: String
    public let description: String
    public let recommendIdList: [Int]
    public let recommendList: [PopupSubmissionRecommendResponseDTO]
    public let imageList: [PopupSubmissionImageRequestDTO]
    public let address: String?
    public let openTime: PopupSubmissionLocalTimeDTO?
    public let closeTime: PopupSubmissionLocalTimeDTO?
    public let instaPostUrl: String?
    public let status: String
}
