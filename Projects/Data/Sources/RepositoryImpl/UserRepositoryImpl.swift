import Core
import Domain
import Foundation
import Moya

public final class UserRepositoryImpl: UserRepositoryProtocol {
    private let tokenStorage: AuthTokenStorage
    private let makeV2Provider: () -> MoyaProvider<V2UserAPI>

    public init(
        tokenStorage: AuthTokenStorage,
        makeV2Provider: @escaping () -> MoyaProvider<V2UserAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
        self.tokenStorage = tokenStorage
        self.makeV2Provider = makeV2Provider
    }

    public func checkNickname(nickname: String) async throws -> Bool {
        try await userRequest {
            try await makeV2Provider().asyncRequest(
                .checkNickname(nickname: nickname),
                decodeDataTo: CheckNicknameDTO.self
            ).isDuplicated
        }
    }

    public func getRecommandList() async throws -> [Recommend] {
        try await userProvider.asyncRequest(.getRecommendList, decodeTo: [RecommendListDTO].self).map { $0.toModel() }
    }

    public func withdraw() async throws {
        try await userRequest {
            try await makeV2Provider().asyncRequestVoid(.withdraw)
        }
        // 탈퇴하면 서버가 이 사용자의 토큰을 받지 않는다. 뒤이은 로그아웃이 서버를 부르지 않도록 기기의 토큰을 먼저 지운다.
        tokenStorage.clear()
    }

    public func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        try await userProvider.asyncRequest(
            .getAlertKeywordList(userUuid: userUuid),
            decodeTo: [KeywordDTO].self
        ).map { $0.toModel() }
    }

    public func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userProvider.asyncRequestVoid(
            .addAlertKeyword(userUuid: userUuid, newAlertKeyword: alertKeyword)
        )
    }

    public func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userProvider.asyncRequestVoid(
            .removeAlertKeyword(userUuid: userUuid, deleteAlertKeyword: alertKeyword)
        )
    }

    public func alertStatus(isAlerted: Bool) async throws -> Bool {
        try await userRequest {
            try await makeV2Provider().asyncRequest(
                .alertStatus(isAlerted: isAlerted),
                decodeDataTo: AlertStatusDTO.self
            ).isAlerted
        }
    }

    public func updateNickname(newNickname: String) async throws {
        try await userRequest {
            try await makeV2Provider().asyncRequestVoid(.updateNickname(nickname: newNickname))
        }
    }

    public func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userProvider.asyncRequest(
            .checkFcmToken(userUuid: userUuid, fcmToken: fcmToken),
            decodeTo: Bool.self
        )
    }

    public func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userProvider.asyncRequestVoid(
            .updateFcmToken(userUuid: userUuid, newFcmToken: fcmToken)
        )
    }

    private var userProvider: MoyaProvider<UserAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

private extension UserRepositoryImpl {
    /// V2 내 정보 요청의 실패를 화면이 안내할 오류로 바꾼다.
    func userRequest<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch let error as NetworkError {
            throw Self.userError(from: error)
        } catch {
            throw UserError.failed
        }
    }

    static func userError(from error: NetworkError) -> UserError {
        switch (error.statusCode, error.serverErrorCode) {
        case (409, 4202):
            return .duplicateNickname
        case (400, 4205):
            return .invalidNickname
        default:
            return .failed
        }
    }
}
