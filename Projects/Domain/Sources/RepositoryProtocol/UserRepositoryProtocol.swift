import Foundation

public protocol UserRepositoryProtocol {
    /// 닉네임 중복 여부 확인. 로그인한 사용자가 부른다.
    /// - Parameter nickname: 닉네임
    /// - Returns: 중복유무 Bool 타입
    /// - Throws: `UserError`
    func checkNickname(nickname: String) async throws -> Bool

    /// 회원 탈퇴. 기기의 인증 토큰은 뒤이은 로그아웃이 지운다.
    /// - Throws: `UserError`
    func withdraw() async throws

    /// 로그인한 사용자의 알림 키워드 목록 (V2)
    /// - Throws: `AlertKeywordError`, 다시 로그인해야 하면 `AuthSessionError`
    func getAlertKeywordList() async throws -> [Keyword]

    /// 로그인한 사용자의 알림 키워드 등록 (V2)
    /// - Parameter alertKeyword: 등록할 키워드. 서버는 받은 문자열을 그대로 저장한다.
    /// - Throws: 이미 있는 키워드면 `AlertKeywordError.alreadyExists`, 다시 로그인해야 하면 `AuthSessionError`
    func addAlertKeyword(alertKeyword: String) async throws

    /// 로그인한 사용자의 알림 키워드 삭제 (V2). 서버에 없는 키워드도 지운 것으로 본다.
    /// - Parameter alertKeyword: 지울 키워드
    /// - Throws: `AlertKeywordError`, 다시 로그인해야 하면 `AuthSessionError`
    func removeAlertKeyword(alertKeyword: String) async throws

    /// 알림 토글
    /// - Parameter isAlerted: 알림 상태 변경 Bool
    /// - Returns: 서버에 저장된 알림 상태
    /// - Throws: `UserError`
    func alertStatus(isAlerted: Bool) async throws -> Bool

    /// 닉네임 수정
    /// - Parameter newNickname: 변경할 닉네임
    /// - Throws: `UserError`
    func updateNickname(newNickname: String) async throws

    /// 로그인한 사용자의 FCM 토큰을 서버에 저장합니다(V2).
    func updateFcmToken(fcmToken: String) async throws
}
