/// 이미 가입한 사용자의 서버 데이터를 한 번 보정하는 마이그레이션
///
/// 서버 요청과, 이 기기에서 사용자별로 마쳤는지 기억하는 기록을 함께 맡는다.
public protocol MigrationRepositoryProtocol {
    /// 이 기기에서 이 사용자의 가입 OS 채우기를 마쳤는지
    func isSignupOsFilled(userUuid: String) -> Bool

    /// 서버에 가입 OS를 보낸다. 서버는 비어 있을 때만 저장하고, 이미 값이 있으면 유지한다.
    func fillSignupOs() async throws

    /// 이 사용자의 가입 OS 채우기를 마쳤다고 기록한다.
    func markSignupOsFilled(userUuid: String)
}
