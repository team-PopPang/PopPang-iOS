import Core
import Domain
import Foundation

public struct KeywordDTO: Decodable, Identifiable, Sendable {
    public var id: String { keyword }
    public let keyword: String

    enum CodingKeys: String, CodingKey {
        case keyword = "alertKeyword"
    }

    public init(keyword: String) {
        self.keyword = keyword
    }
}

public extension KeywordDTO {
    func toModel() -> Keyword {
        Keyword(keyword: keyword)
    }
}

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

public struct RecommendListDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let recommendName: String

    public init(id: Int, recommendName: String) {
        self.id = id
        self.recommendName = recommendName
    }
}

public extension RecommendListDTO {
    func toModel() -> Recommend {
        Recommend(id: id, recommendName: recommendName)
    }
}

public struct RegionListDTO: Decodable, Hashable, Sendable {
    public let region: String
    public let districtList: [String]

    public init(region: String, districtList: [String]) {
        self.region = region
        self.districtList = districtList
    }

    func toEntity() -> RegionList {
        RegionList(region: region, districtList: districtList)
    }
}

public struct UserDTO: Codable, Sendable {
    public let userUuid: String
    public let uid: String
    public let provider: String
    public let email: String?
    public let nickname: String?
    public let role: String
    public let isAlerted: Bool
    public let fcmToken: String?
    public let alertKeywordList: [String]?
    public let recommendList: [Int]?

    public init(
        userUuid: String,
        uid: String,
        provider: String,
        email: String?,
        nickname: String?,
        role: String,
        isAlerted: Bool,
        fcmToken: String?,
        alertKeywordList: [String]?,
        recommendList: [Int]?
    ) {
        self.userUuid = userUuid
        self.uid = uid
        self.provider = provider
        self.email = email
        self.nickname = nickname
        self.role = role
        self.isAlerted = isAlerted
        self.fcmToken = fcmToken
        self.alertKeywordList = alertKeywordList
        self.recommendList = recommendList
    }
}

public extension UserDTO {
    func toModel() -> Domain.User {
        Domain.User(
            userUuid: userUuid,
            uid: uid,
            provider: provider,
            email: email,
            nickname: nickname,
            role: role,
            isAlerted: isAlerted,
            fcmToken: fcmToken,
            alertKeywordList: alertKeywordList,
            recommendList: recommendList
        )
    }

    static let adminUser = UserDTO(
        userUuid: "1234",
        uid: "0000",
        provider: "kakao",
        email: "index@example.com",
        nickname: "김동현",
        role: "user",
        isAlerted: false,
        fcmToken: "",
        alertKeywordList: ["팝업스토어", "카페"],
        recommendList: [1, 2]
    )
}

public struct CheckNicknameDTO: Decodable, Sendable {
    public let isDuplicated: Bool

    public init(isDuplicated: Bool) {
        self.isDuplicated = isDuplicated
    }
}

public struct GoogleResponseDTO: Sendable {
    public var oauthId: String = ""
    public var idToken: String = ""

    public init(oauthId: String = "", idToken: String = "") {
        self.oauthId = oauthId
        self.idToken = idToken
    }
}
