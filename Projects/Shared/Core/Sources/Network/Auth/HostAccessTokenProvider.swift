import Foundation

/// 네트워크 계층 밖(React Native 화면 등)에서 V2 API를 부를 때 쓸 Access Token을 건네고,
/// 그 토큰이 401을 받으면 앱 요청과 같은 `AccessTokenRefresher`로 갱신한다.
///
/// 마지막으로 건넨 토큰을 기억해 두었다가 갱신할 때 만료된 토큰으로 넘긴다.
/// 그래서 다른 요청(앱 요청이나 같은 화면의 다른 요청)이 이미 갱신했으면 다시 갱신하지 않고 새 토큰을 돌려준다.
public actor HostAccessTokenProvider {
    private let storage: AuthTokenStorage
    private let refresher: AccessTokenRefresher
    private let sessionEvents: AuthSessionEvents?
    /// 마지막으로 건넨 Access Token. 이 토큰으로 보낸 요청이 401을 받으면 갱신을 요청한다.
    private var lastProvidedAccessToken: String?

    public init(authentication: AuthenticationPlugin) {
        storage = authentication.storage
        refresher = authentication.refresher
        sessionEvents = authentication.sessionEvents
    }

    /// - Parameter forceRefresh: 건넨 토큰으로 보낸 요청이 401을 받았으면 `true`.
    /// - Returns: 로그아웃 상태이거나 갱신에 실패하면 `nil`.
    ///   Refresh Token도 쓸 수 없으면(`AuthSessionError.loginRequired`) 앱의 다른 요청처럼 다시 로그인해야 한다고 알린다.
    public func accessToken(forceRefresh: Bool) async -> String? {
        guard let storedAccessToken = storage.loadTokens()?.accessToken else { return nil }
        guard forceRefresh else {
            lastProvidedAccessToken = storedAccessToken
            return storedAccessToken
        }

        do {
            return try await refresher.refreshAccessToken(expired: lastProvidedAccessToken ?? storedAccessToken)
        } catch AuthSessionError.loginRequired {
            sessionEvents?.notifyLoginRequired()
            return nil
        } catch {
            return nil
        }
    }
}
