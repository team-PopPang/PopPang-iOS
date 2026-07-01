import ComposableArchitecture
import Domain

public struct ProfileFeatureClient: Sendable {
    public var checkNickname: @Sendable (String) async throws -> Bool
    public var updateNickname: @Sendable (String, String) async throws -> Void
    public var hardDeleteUser: @Sendable (String) async throws -> Void
    public var alertStatus: @Sendable (String, Bool) async throws -> Void

    public init(
        checkNickname: @escaping @Sendable (String) async throws -> Bool,
        updateNickname: @escaping @Sendable (String, String) async throws -> Void,
        hardDeleteUser: @escaping @Sendable (String) async throws -> Void,
        alertStatus: @escaping @Sendable (String, Bool) async throws -> Void
    ) {
        self.checkNickname = checkNickname
        self.updateNickname = updateNickname
        self.hardDeleteUser = hardDeleteUser
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
            updateNickname: { userUuid, newNickname in
                try await userUsecaseBox.usecase.updateNickname(
                    userUuid: userUuid,
                    newNickname: newNickname
                )
            },
            hardDeleteUser: { userUuid in
                try await userUsecaseBox.usecase.hardDeleteUser(userUuid: userUuid)
            },
            alertStatus: { userUuid, isAlerted in
                try await userUsecaseBox.usecase.alertStatus(
                    userUuid: userUuid,
                    isAlerted: isAlerted
                )
            }
        )
    }
}

private struct ProfileFeatureUnimplementedError: Error {}

extension ProfileFeatureClient {
    public static let unimplemented = Self(
        checkNickname: { _ in throw ProfileFeatureUnimplementedError() },
        updateNickname: { _, _ in throw ProfileFeatureUnimplementedError() },
        hardDeleteUser: { _ in throw ProfileFeatureUnimplementedError() },
        alertStatus: { _, _ in throw ProfileFeatureUnimplementedError() }
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
