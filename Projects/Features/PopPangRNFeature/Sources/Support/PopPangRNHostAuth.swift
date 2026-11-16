import Foundation
@_implementationOnly import PopPangReactNativeHost

/// React Native 화면이 V2 API를 부를 때 쓸 Access Token을 앱에서 넘겨준다.
///
/// RN은 요청할 때마다 네이티브 모듈(`PopPangHostAuth`)로 토큰을 받고, 서버가 401을 주면 `forceRefresh: true`로 다시 받는다.
/// 토큰 저장과 갱신은 앱의 인증 계층이 맡는다. composition root에서 한 번 연결한다.
public enum PopPangRNHostAuth {
    /// - Parameter provider: Access Token을 돌려준다. 로그아웃 상태이거나 갱신에 실패하면 `nil`.
    public static func setAccessTokenProvider(
        _ provider: @escaping @Sendable (_ forceRefresh: Bool) async -> String?
    ) {
        PopPangHostAuth.setAccessTokenProvider { forceRefresh, completion in
            Task {
                completion(await provider(forceRefresh))
            }
        }
    }
}
