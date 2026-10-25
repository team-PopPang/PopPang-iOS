import Core
import Domain
import Foundation
import Moya

/// 마이그레이션 요청을 보내고, 마친 사용자를 기기에 기록한다.
///
/// 기록은 앱을 지우면 함께 지워진다. 다시 설치해 한 번 더 보내도 서버가 이미 있는 값을 유지하므로 괜찮다.
public final class MigrationRepositoryImpl: MigrationRepositoryProtocol {
    private let store: Storing
    private let makeProvider: () -> MoyaProvider<MigrationAPI>

    public init(
        store: Storing,
        makeProvider: @escaping () -> MoyaProvider<MigrationAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
        self.store = store
        self.makeProvider = makeProvider
    }

    public func isSignupOsFilled(userUuid: String) -> Bool {
        signupOsFilledUsers.contains(userUuid)
    }

    public func fillSignupOs() async throws {
        try await makeProvider().asyncRequestVoid(.fillSignupOs)
    }

    public func markSignupOsFilled(userUuid: String) {
        let users = signupOsFilledUsers
        guard !users.contains(userUuid) else { return }
        do {
            try store.set(users + [userUuid], forKey: Key.signupOsFilledUsers)
        } catch {
            // 기록하지 못하면 다음 실행 때 한 번 더 보낸다. 서버가 이미 있는 값을 유지하므로 결과는 같다.
            Logger.w("가입 OS 채우기 기록 실패: \(error.localizedDescription)")
        }
    }
}

private extension MigrationRepositoryImpl {
    enum Key {
        static let signupOsFilledUsers = "migration.signupOsFilledUsers"
    }

    var signupOsFilledUsers: [String] {
        store.value(forKey: Key.signupOsFilledUsers) ?? []
    }
}
