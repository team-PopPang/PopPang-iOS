import Core
import Domain
import Foundation
import Moya

public final class UserRepositoryImpl: UserRepositoryProtocol {
    private let makeV2Provider: () -> MoyaProvider<V2UserAPI>

    public init(
        makeV2Provider: @escaping () -> MoyaProvider<V2UserAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
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
        // 기기의 토큰은 뒤이은 로그아웃 전환이 지운다. 여기서 먼저 지우면 아직 화면에서 진행 중인 요청이
        // 토큰 없이 실패해 세션 만료 알림이 로그아웃 전환과 겹친다.
        try await userRequest {
            do {
                try await makeV2Provider().asyncRequestVoid(.withdraw)
            } catch let error as NetworkError where error.statusCode == 404 && error.serverErrorCode == 4201 {
                // 앞선 탈퇴 요청의 응답을 받지 못한 채 다시 보냈다. 사용자가 이미 없으므로 탈퇴한 것으로 본다.
            }
        }
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
    ///
    /// 다시 로그인해야 하는 경우(`AuthSessionError`)는 그대로 던진다. 앱이 로그인 화면으로 보내므로 화면이 실패로 안내하지 않게 하기 위해서다.
    func userRequest<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch let error as NetworkError {
            throw Self.userError(from: error)
        } catch let error as AuthSessionError {
            throw error
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
