import Foundation

public protocol UserRepositoryProtocol {
    /// 닉네임 중복 여부 확인. 로그인한 사용자가 부른다.
    /// - Parameter nickname: 닉네임
    /// - Returns: 중복유무 Bool 타입
    /// - Throws: `UserError`
    func checkNickname(nickname: String) async throws -> Bool

    /// 추천 카테고리 리스트 가져오기
    /// - Returns: [Recommend]
    func getRecommandList() async throws -> [Recommend]

    /// 회원 탈퇴. 성공하면 기기의 인증 토큰을 지운다.
    /// - Throws: `UserError`
    func withdraw() async throws

    /// 키워드 리스트 가져오기
    /// - Returns: [Keyword]
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword]

    /// 알림키워드 추가하기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - alertKeyword: 알림 키워드 고유값
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws

    /// 알림키워드 삭제하기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - alertKeyword: 알림 키워드 고유값
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws

    /// 알림 토글
    /// - Parameter isAlerted: 알림 상태 변경 Bool
    /// - Returns: 서버에 저장된 알림 상태
    /// - Throws: `UserError`
    func alertStatus(isAlerted: Bool) async throws -> Bool

    /// 닉네임 수정
    /// - Parameter newNickname: 변경할 닉네임
    /// - Throws: `UserError`
    func updateNickname(newNickname: String) async throws

    /// FCM토큰 일치 확인
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - fcmToken: fcmToken
    /// - Returns: 일치하면 true
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool

    /// FCM토큰 갱신
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - fcmToken: fcmToken
    func updateFcmToken(userUuid: String, fcmToken: String) async throws
}
