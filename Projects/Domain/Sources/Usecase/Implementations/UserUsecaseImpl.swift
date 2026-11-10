public final class UserUsecaseImpl: UserUsecaseProtocol {
    private let userRepository: UserRepositoryProtocol

    public init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    public func checkNickname(nickname: String) async throws -> Bool {
        try await userRepository.checkNickname(nickname: nickname)
    }

    public func withdraw() async throws {
        try await userRepository.withdraw()
    }

    public func getAlertKeywordList() async throws -> [Keyword] {
        try await userRepository.getAlertKeywordList()
    }

    public func addAlertKeyword(alertKeyword: String) async throws {
        try await userRepository.addAlertKeyword(alertKeyword: alertKeyword)
    }

    public func removeAlertKeyword(alertKeyword: String) async throws {
        try await userRepository.removeAlertKeyword(alertKeyword: alertKeyword)
    }

    public func alertStatus(isAlerted: Bool) async throws -> Bool {
        try await userRepository.alertStatus(isAlerted: isAlerted)
    }

    public func updateNickname(newNickname: String) async throws {
        try await userRepository.updateNickname(newNickname: newNickname)
    }

    public func updateFcmToken(fcmToken: String) async throws {
        try await userRepository.updateFcmToken(fcmToken: fcmToken)
    }
}
