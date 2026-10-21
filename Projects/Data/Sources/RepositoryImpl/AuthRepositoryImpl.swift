import Core
import Domain
import Foundation
import Moya

/// 소셜 로그인과 V2 인증 API를 묶는다.
///
/// 제공자마다 다른 SDK 로그인은 `SocialLoginStrategy`에 맡기고, 서버 로그인·가입·토큰 저장은 모든 제공자에 같은 방식으로 한다.
/// 토큰은 이 Repository가 `AuthTokenStorage`에 저장하고 feature에는 넘기지 않는다.
public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let strategies: [Provider: SocialLoginStrategy]
    private let tokenStorage: AuthTokenStorage
    private let refreshTokens: AccessTokenRefresher.Refresh
    private let makeProvider: () -> MoyaProvider<AuthAPI>

    public init(
        strategies: [SocialLoginStrategy] = [
            KakaoLoginStrategy(),
            AppleLoginStrategy(),
            GoogleLoginStrategy(),
        ],
        tokenStorage: AuthTokenStorage,
        refreshTokens: @escaping AccessTokenRefresher.Refresh = AuthTokenRefresh.live(),
        makeProvider: @escaping () -> MoyaProvider<AuthAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
        self.strategies = Dictionary(strategies.map { ($0.provider, $0) }) { first, _ in first }
        self.tokenStorage = tokenStorage
        self.refreshTokens = refreshTokens
        self.makeProvider = makeProvider
    }

    public func login(with provider: Provider) async throws -> LoginResult {
        guard let strategy = strategies[provider] else { throw AuthError.failed }

        let credential: SocialCredential
        do {
            credential = try await strategy.login()
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.e("\(provider.rawValue) 소셜 로그인 실패: \(error.localizedDescription)")
            throw AuthError.failed
        }

        let data: V2LoginDataDTO
        do {
            data = try await makeProvider().asyncRequest(.login(credential), decodeDataTo: V2LoginDataDTO.self)
        } catch {
            throw Self.loginError(from: error)
        }
        return try save(data, provider: provider)
    }

    public func signup(with provider: Provider, request: SignupRequest) async throws -> User {
        guard tokenStorage.loadSignupToken() != nil else { throw AuthError.signupSessionExpired }

        let data: V2LoginDataDTO
        do {
            data = try await makeProvider().asyncRequest(
                .signup(provider: provider, request: V2SignupRequestDTO(request)),
                decodeDataTo: V2LoginDataDTO.self
            )
        } catch {
            let authError = Self.signupError(from: error)
            if authError == .signupSessionExpired {
                tokenStorage.removeSignupToken()
            }
            throw authError
        }

        guard case let .completed(user) = try save(data, provider: provider) else {
            // 가입 응답은 항상 COMPLETED여야 한다. 가입이 끝나지 않았으면 소셜 로그인부터 다시 해서 상태를 확인한다.
            tokenStorage.removeSignupToken()
            throw AuthError.signupSessionExpired
        }
        return user
    }

    public func checkSignupNickname(_ nickname: String) async throws -> Bool {
        try await signupRequest {
            try await makeProvider().asyncRequest(
                .signupNicknameDuplicated(nickname: nickname),
                decodeDataTo: CheckNicknameDTO.self
            ).isDuplicated
        }
    }

    public func fetchSignupRecommendList() async throws -> [Recommend] {
        // 명세 RECO-01: V2 성공 응답도 `APIResponse`로 감싸지 않은 배열이다.
        try await signupRequest {
            try await makeProvider().asyncRequest(.signupRecommendList, decodeTo: [RecommendListDTO].self)
                .map { $0.toModel() }
        }
    }

    public func restoreSession() async throws -> User? {
        // 가입 도중 앱을 다시 켰다면 가입 전용 토큰은 이미 만료됐을 수 있어 소셜 로그인부터 다시 한다.
        tokenStorage.removeSignupToken()

        guard tokenStorage.loadTokens() != nil else {
            _ = tokenStorage.removeIncompleteTokens()
            return nil
        }

        do {
            return try await makeProvider().asyncRequest(.me, decodeDataTo: V2AuthUserDTO.self).toEntity()
        } catch AuthSessionError.loginRequired {
            return nil
        } catch let error as NetworkError where error.statusCode == 404 && error.serverErrorCode == 4201 {
            // 토큰의 사용자가 서버에 없다.
            tokenStorage.removeTokens()
            return nil
        }
    }

    public func logout() async {
        // 기기의 토큰을 먼저 지운다. 서버를 기다리는 동안 다시 로그인해도 새 토큰을 지우지 않고,
        // 만료된 Access Token 때문에 갱신이 일어나 새 토큰이 남는 일도 없다.
        let tokens = tokenStorage.loadTokens()
        tokenStorage.clear()

        guard let tokens else { return }
        do {
            try await makeProvider().asyncRequestVoid(.logout(accessToken: tokens.accessToken))
        } catch let error as NetworkError where error.isExpiredToken {
            // Access Token은 짧게 만료되므로 로그아웃할 때 이미 만료된 경우가 많다.
            // 서버의 Refresh 세션을 지우려고 꺼내 둔 Refresh Token으로 한 번 갱신해 다시 보낸다. 새 토큰은 저장하지 않는다.
            do {
                let refreshed = try await refreshTokens(tokens.refreshToken)
                try await makeProvider().asyncRequestVoid(.logout(accessToken: refreshed.accessToken))
            } catch {
                Logger.w("서버 로그아웃 실패: \(error.localizedDescription)")
            }
        } catch {
            // 서버 세션 삭제가 확인되지 않아도 사용자가 원한 로그아웃이므로 기기의 토큰은 이미 지웠다.
            Logger.w("서버 로그아웃 실패: \(error.localizedDescription)")
        }
    }
}

private extension AuthRepositoryImpl {
    /// 가입 화면에서 가입 전용 토큰으로 부르는 요청. 가입 단계가 끝났으면 가입 전용 토큰을 지우고 로그인부터 다시 하게 한다.
    func signupRequest<T>(_ request: () async throws -> T) async throws -> T {
        guard tokenStorage.loadSignupToken() != nil else { throw AuthError.signupSessionExpired }

        do {
            return try await request()
        } catch let error as NetworkError where Self.isSignupSessionEnded(error) {
            tokenStorage.removeSignupToken()
            throw AuthError.signupSessionExpired
        } catch {
            throw AuthError.failed
        }
    }

    /// 가입 전용 토큰이 만료됐거나(5002) 최신 토큰이 아니거나(5014) 없다(5006).
    static func isSignupSessionEnded(_ error: NetworkError) -> Bool {
        error.statusCode == 401 && [5002, 5014, 5006].contains(error.serverErrorCode)
    }

    /// 로그인·가입 응답의 토큰을 저장하고 결과를 돌려준다.
    func save(_ data: V2LoginDataDTO, provider: Provider) throws -> LoginResult {
        do {
            switch data.signupStatus {
            case "COMPLETED":
                guard let user = data.user,
                      let accessToken = data.accessToken,
                      let refreshToken = data.refreshToken
                else {
                    throw AuthError.failed
                }
                try tokenStorage.saveTokens(AuthTokens(accessToken: accessToken, refreshToken: refreshToken))
                tokenStorage.removeSignupToken()
                return .completed(user.toEntity())

            case "PENDING":
                guard let signupToken = data.signupToken else { throw AuthError.failed }
                try tokenStorage.saveSignupToken(signupToken)
                return .pending(provider)

            default:
                throw AuthError.failed
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.e("인증 토큰 저장 실패: \(error.localizedDescription)")
            throw AuthError.failed
        }
    }

    static func loginError(from error: Error) -> AuthError {
        guard let error = error as? NetworkError else { return .failed }

        switch (error.statusCode, error.serverErrorCode) {
        case (401, 5010):
            return .inactiveAccount
        case (409, 5016):
            return .socialAccountConflict
        default:
            return .failed
        }
    }

    static func signupError(from error: Error) -> AuthError {
        guard let error = error as? NetworkError else { return .failed }

        switch (error.statusCode, error.serverErrorCode) {
        case (409, 4202):
            return .duplicateNickname
        case (400, 5017), (400, 4304):
            return .invalidSignupRequest
        case (401, 5010):
            return .inactiveAccount
        // 가입 전용 토큰 만료·불일치, 이미 가입 완료, 제공자 불일치. 소셜 로그인 결과로 현재 상태를 다시 확인한다.
        case (401, 5002), (401, 5014), (401, 5006), (409, 4204), (403, 5012):
            return .signupSessionExpired
        default:
            return .failed
        }
    }
}
