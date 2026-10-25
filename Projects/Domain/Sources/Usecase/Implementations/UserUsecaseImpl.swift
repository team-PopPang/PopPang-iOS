public final class UserUsecaseImpl: UserUsecaseProtocol {
    private let userRepository: UserRepositoryProtocol

    public init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    public func checkNickname(nickname: String) async throws -> Bool {
        try await userRepository.checkNickname(nickname: nickname)
    }

    public func getRecommandList() async throws -> [Recommend] {
        try await userRepository.getRecommandList()
    }

    public func withdraw() async throws {
        try await userRepository.withdraw()
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

    public func alertStatus(isAlerted: Bool) async throws -> Bool {
        try await userRepository.alertStatus(isAlerted: isAlerted)
    }

    public func updateNickname(newNickname: String) async throws {
        try await userRepository.updateNickname(newNickname: newNickname)
    }

    public func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userRepository.checkFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }

    public func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userRepository.updateFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }
}
