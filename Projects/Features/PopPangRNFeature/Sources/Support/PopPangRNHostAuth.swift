import Foundation
@_implementationOnly import PopPangReactNativeHost

/// React Native 화면이 V2 API를 부를 때 쓸 Access Token을 앱에서 받는 연결.
public enum PopPangRNHostAuth {
    /// RN 네이티브 모듈 `PopPangHostAuth`에 Access Token 공급자를 등록한다. 모듈이 전역으로 들고 있어 마지막에 등록한 공급자를 쓴다.
    ///
    /// - Parameter provider: `rejectedAccessToken`이 `nil`이면 지금 쓸 토큰, 값이 있으면 그 토큰으로 보낸 요청이 401을 받은 뒤다.
    ///   `expired`는 401의 서버 코드가 5002(만료)인지다. 토큰을 주지 못하면 `accessToken`을 `nil`로 돌려주고,
    ///   잠시 뒤 다시 하면 되는 실패면 `temporaryFailure`를 `true`로 돌려준다.
    public static func setAccessTokenProvider(
        _ provider: @escaping @Sendable (
            _ rejectedAccessToken: String?,
            _ expired: Bool
        ) async -> (accessToken: String?, temporaryFailure: Bool)
    ) {
        PopPangHostAuth.setAccessTokenProvider { rejectedAccessToken, expired, completion in
            let completion = CompletionBox(completion)
            Task {
                let result = await provider(rejectedAccessToken, expired)
                completion.call(result.accessToken, result.temporaryFailure)
            }
        }
    }
}

/// RN이 준 Objective-C completion block을 `Task`로 넘기기 위한 상자. RN promise는 어느 스레드에서 끝내도 된다.
private struct CompletionBox: @unchecked Sendable {
    let call: (String?, Bool) -> Void

    init(_ call: @escaping (String?, Bool) -> Void) {
        self.call = call
    }
}
