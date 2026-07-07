public final class UserUsecaseImpl: UserUsecaseProtocol {
    private let userRepository: UserRepositoryProtocol

    public init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    public func checkNickname(nickname: String) async throws -> Bool {
        try await userRepository.checkNickname(nickname: nickname)
    }

    public func autoLogin(userUuid: String) async throws -> User {
        try await userRepository.autoLogin(userUuid: userUuid)
    }

    public func getRecommandList() async throws -> [Recommend] {
        try await userRepository.getRecommandList()
    }

    public func hardDeleteUser(userUuid: String) async throws {
        try await userRepository.hardDeleteUser(userUuid: userUuid)
    }

    public func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        try await userRepository.getAlertKeywordList(userUuid: userUuid)
    }

    public func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.addAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }

    public func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.removeAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }

    public func alertStatus(userUuid: String, isAlerted: Bool) async throws {
        try await userRepository.alertStatus(userUuid: userUuid, isAlerted: isAlerted)
    }

    public func updateNickname(userUuid: String, newNickname: String) async throws {
        try await userRepository.updateNickname(userUuid: userUuid, newNickname: newNickname)
    }

    public func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userRepository.checkFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }

    public func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userRepository.updateFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }
}
