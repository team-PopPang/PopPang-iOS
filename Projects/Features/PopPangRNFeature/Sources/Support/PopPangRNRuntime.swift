import Core
import Foundation
import PopPangRN

/// React Native 런타임(Nativepiece `PopPangRN` 패키지)을 시작하고, RN이 앱에 요청하는 기능을 연결한다.
///
/// Nativepiece 런타임은 앱 전체에 하나라서(`Nativepiece.shared`) TCA `DependencyValues`가 아니라 앱 시작 때 한 번 연결한다.
public enum PopPangRNRuntime {
    /// 앱을 시작할 때 한 번 부른다. RN 화면이 `getAccessToken`을 요청하면 앱 요청과 같은 `AuthenticationPlugin`으로 답한다.
    ///
    /// 런타임을 미리 띄우지 않는다(`prewarm: false`). 제보 화면은 자주 열지 않으므로 앱 시작 비용을 늘리지 않고,
    /// 처음 열 때 JS 번들을 불러온다. 이전 RN 산출물도 화면을 열 때 런타임을 만들었다.
    @MainActor
    public static func start(authentication: AuthenticationPlugin) {
        PopPangRN.start(host: AccessTokenHost(authentication: authentication), prewarm: false)
    }
}

/// 계약(`nativepiece.contract.ts`)의 `calls.getAccessToken`을 처리한다. `PopPangRN.start(host:)`가 앱이 살아 있는 동안 들고 있다.
@MainActor
private final class AccessTokenHost: PopPangRNHost {
    private let authentication: AuthenticationPlugin

    init(authentication: AuthenticationPlugin) {
        self.authentication = authentication
    }

    func getAccessToken(_ request: PopPangRN.GetAccessTokenRequest) async throws -> PopPangRN.GetAccessTokenResponse {
        // RN은 오류 code로 안내 문구를 고른다 (PopPang-RN `HOST_AUTH_ERROR`).
        switch await authentication.hostAccessToken(rejected: request.rejectedAccessToken, expired: request.expired) {
        case let .accessToken(accessToken):
            return .init(accessToken: accessToken)
        case .loginRequired:
            throw NativepieceCallError(code: "login_required", message: "로그인 정보가 만료되었습니다.")
        case .temporaryFailure:
            throw NativepieceCallError(code: "temporary_failure", message: "로그인 정보를 잠시 확인하지 못했습니다.")
        }
    }
}
