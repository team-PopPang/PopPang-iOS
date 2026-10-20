import Domain
import Foundation

/// V2 로그인·가입·내 정보 조회 응답의 사용자 정보
public struct V2AuthUserDTO: Decodable, Equatable, Sendable {
    public let userUuid: String
    public let provider: String?
    public let email: String?
    public let nickname: String?
    public let role: String?
    public let isAlerted: Bool

    func toEntity() -> User {
        User(
            userUuid: userUuid,
            uid: "",
            provider: provider ?? "",
            email: email,
            nickname: nickname,
            role: role ?? "",
            isAlerted: isAlerted,
            fcmToken: nil,
            alertKeywordList: nil,
            recommendList: nil
        )
    }
}
