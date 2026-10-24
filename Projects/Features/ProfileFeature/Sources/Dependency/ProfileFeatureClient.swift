import ComposableArchitecture
import Domain

public struct ProfileFeatureClient: Sendable {
    public var checkNickname: @Sendable (String) async throws -> Bool
    public var updateNickname: @Sendable (String) async throws -> Void
    public var withdraw: @Sendable () async throws -> Void
    /// 바꿀 알림 상태를 보내고 서버에 저장된 알림 상태를 돌려받는다.
    public var alertStatus: @Sendable (Bool) async throws -> Bool

    public init(
        checkNickname: @escaping @Sendable (String) async throws -> Bool,
        updateNickname: @escaping @Sendable (String) async throws -> Void,
        withdraw: @escaping @Sendable () async throws -> Void,
        alertStatus: @escaping @Sendable (Bool) async throws -> Bool
    ) {
        self.checkNickname = checkNickname
        self.updateNickname = updateNickname
        self.withdraw = withdraw
        self.alertStatus = alertStatus
    }

    public static func live(
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        let userUsecaseBox = UserUsecaseBox(userUsecase)

        return Self(
            checkNickname: { nickname in
                try await userUsecaseBox.usecase.checkNickname(nickname: nickname)
            },
            updateNickname: { newNickname in
                try await userUsecaseBox.usecase.updateNickname(newNickname: newNickname)
            },
            withdraw: {
                try await userUsecaseBox.usecase.withdraw()
            },
            alertStatus: { isAlerted in
                try await userUsecaseBox.usecase.alertStatus(isAlerted: isAlerted)
            }
        )
    }
}

private struct ProfileFeatureUnimplementedError: Error {}

extension ProfileFeatureClient {
    public static let unimplemented = Self(
        checkNickname: { _ in throw ProfileFeatureUnimplementedError() },
        updateNickname: { _ in throw ProfileFeatureUnimplementedError() },
        withdraw: { throw ProfileFeatureUnimplementedError() },
        alertStatus: { _ in throw ProfileFeatureUnimplementedError() }
    )
}

private final class UserUsecaseBox: @unchecked Sendable {
    let usecase: UserUsecaseProtocol

    init(_ usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
}

extension ProfileFeatureClient: DependencyKey {
    public static let liveValue = Self.unimplemented
}

extension ProfileFeatureClient: TestDependencyKey {
    public static let testValue = Self.unimplemented
}

extension DependencyValues {
    public var profileFeatureClient: ProfileFeatureClient {
        get { self[ProfileFeatureClient.self] }
        set { self[ProfileFeatureClient.self] = newValue }
    }
}
