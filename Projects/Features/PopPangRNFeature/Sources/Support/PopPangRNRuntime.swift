import Foundation
import PopPangRN

/// React Native 화면의 Access Token 요청에 대한 앱의 답.
public enum PopPangRNAccessTokenResult: Equatable, Sendable {
    case accessToken(String)
    /// 다시 로그인해야 한다. RN은 로그인 만료 안내를 보인다.
    case loginRequired
    /// 네트워크·서버 문제로 지금은 토큰을 주지 못했다. RN은 잠시 후 다시 시도하라는 안내를 보인다.
    case temporaryFailure
}

/// React Native 화면이 V2 API용 Access Token을 앱에 요청할 때 부르는 공급자.
///
/// `rejectedAccessToken`이 `nil`이면 지금 쓸 토큰, 값이 있으면 그 토큰으로 보낸 요청이 401을 받은 뒤다.
/// `expired`는 401의 서버 코드가 5002(만료)인지다.
public typealias PopPangRNAccessTokenProvider = @Sendable (
    _ rejectedAccessToken: String?,
    _ expired: Bool
) async -> PopPangRNAccessTokenResult

/// React Native 런타임(Nativepiece `PopPangRN` 패키지)을 시작하고, RN이 앱에 요청하는 기능을 연결한다.
public enum PopPangRNRuntime {
    /// 앱을 시작할 때 한 번 부른다. RN 화면이 `getAccessToken`을 요청하면 `accessTokenProvider`로 답한다.
    ///
    /// 런타임을 미리 띄우지 않는다(`prewarm: false`). 제보 화면은 자주 열지 않으므로 앱 시작 비용을 늘리지 않고,
    /// 처음 열 때 JS 번들을 불러온다. 이전 RN 산출물도 화면을 열 때 런타임을 만들었다.
    @MainActor
    public static func start(accessTokenProvider: @escaping PopPangRNAccessTokenProvider) {
        PopPangRN.start(host: AccessTokenHost(provider: accessTokenProvider), prewarm: false)
    }
}

/// 계약(`nativepiece.contract.ts`)의 `calls.getAccessToken`을 처리한다. `PopPangRN.start(host:)`가 앱이 살아 있는 동안 들고 있다.
@MainActor
private final class AccessTokenHost: PopPangRNHost {
    private let provider: PopPangRNAccessTokenProvider

    init(provider: @escaping PopPangRNAccessTokenProvider) {
        self.provider = provider
    }

    func getAccessToken(_ request: PopPangRN.GetAccessTokenRequest) async throws -> PopPangRN.GetAccessTokenResponse {
        // RN은 오류 code로 안내 문구를 고른다 (PopPang-RN `HOST_AUTH_ERROR`).
        switch await provider(request.rejectedAccessToken, request.expired) {
        case let .accessToken(accessToken):
            return .init(accessToken: accessToken)
        case .loginRequired:
            throw NativepieceCallError(code: "login_required", message: "로그인 정보가 만료되었습니다.")
        case .temporaryFailure:
            throw NativepieceCallError(code: "temporary_failure", message: "로그인 정보를 잠시 확인하지 못했습니다.")
        }
    }
}
