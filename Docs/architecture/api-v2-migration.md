# V2 API 마이그레이션

이 문서는 앱이 호출하는 서버 API를 V1에서 V2로 옮기는 계획이에요. 어떤 순서로 옮기는지, 단계마다 앱 코드의 무엇을 바꾸는지, 아직 정하지 못한 것이 무엇인지 적어요.

## 원본 명세

API별 요청·응답·에러 코드는 서버 팀이 만든 마이그레이션 명세를 봐요.

| 항목 | 값 |
| --- | --- |
| 명세 | PopPang 앱 API V1 → V2 마이그레이션 명세 (HTML 9개, 2026-10-15 생성) |
| 기준 서버 코드 | PopPang-BE-Prod `origin/main` `cc55e51` |
| 대상 | 앱이 호출하는 API 57개 (V2 대응 55개, V2가 없는 V1 API 2개) |
| 공개 범위 | 내부용이에요. 이 저장소는 공개 저장소라서 명세 원문과 API 전체 표는 싣지 않아요. 명세가 필요하면 팀에 요청해요. |

명세에 없거나 명세가 `확인 필요`로 남긴 내용은 추측해서 구현하지 않아요. 이 문서의 [정해야 할 것](#정해야-할-것)에 올리고 정한 뒤에 진행해요.

## 기본 원칙

- **V1과 V2를 함께 써요.** V1은 앱 전환이 끝날 때까지 서버에서 그대로 동작해요. 묶음 하나씩 옮기는 동안 V1 호출과 V2 호출이 앱 안에 같이 있어도 돼요.
- **V2 경로는 명세의 값을 그대로 써요.** `/api/v1`을 `/api/v2`로 기계적으로 바꾸지 않아요. 사용자 종속 API는 경로의 `{userUuid}`가 빠지고, method가 바뀌는 API도 있어요.
- **인증 헤더는 API마다 정해요.** V1 요청에는 `Authorization` 헤더를 보내지 않아요. V2는 API에 따라 헤더 없음, `Bearer {accessToken}`, `Bearer {signupToken}` 가운데 하나예요.
- **성공 응답 형식도 API마다 달라요.** V2라도 `APIResponse`로 감싸지 않는 API가 있어서, 모든 응답에 같은 디코더를 쓰지 않아요.
- **로그인한 뒤에만 탐색해요.** V2에서는 로그인 전에 쓰던 조회 API에도 Access Token이 필요해요. 로그인 전 화면이 부르는 API는 V2로 바꾸기 전에 따로 확인해요.

## 단계

| 단계 | 내용 | 명세 묶음 | 화면 동작 변경 | 상태 |
| --- | --- | --- | --- | --- |
| 1 | 공통 네트워크 기반 | COMMON | 없음 | 완료 (#117) |
| 2 | 로그인 모듈과 유저 엔티티 | A1, A2, USER-01 | 있음 (기존 사용자 재로그인) | 완료 (#119) |
| 3 | 내 정보 | U | 없음 | 진행 중 (프로필 화면 #120) |
| 4~ | 나머지 화면 | P1, P2, P3, F, K, USER-06 | 거의 없음 | [feature별로 진행](#남은-작업-feature별-전환) |

- 1단계와 2단계는 순서대로 해요. 2단계는 1단계의 토큰 처리를 쓰고, 나머지 단계는 2단계가 저장한 Access Token을 써요.
- 4단계부터는 feature 단위로 옮겨요. 순서와 진행 상태는 [남은 작업](#남은-작업-feature별-전환)에 있어요.
- 2단계 중간 상태로는 출시하지 않아요. 2단계가 끝나야 로그인, 가입, 앱 시작, 로그아웃이 모두 V2로 맞춰져요.

## 1단계: 공통 네트워크 기반

모든 V2 API가 함께 쓰는 기반을 `Core`에 만들어요. 이 단계에서는 어떤 API도 V2로 바꾸지 않아서 앱 동작은 그대로예요.

### 구성 요소

| 구성 요소 | 위치 | 역할 |
| --- | --- | --- |
| `APIVersion`, `APIAuthorization` | `Core/Sources/Network/BaseAPI.swift` | API target마다 버전(`v1`·`v2`)과 인증 종류(`none`·`access`·`signup`)를 정해요. 기본값은 `v1`, `none`이라 기존 target은 그대로예요. V1 target에는 인증 종류를 정해도 헤더를 붙이지 않아요(`resolvedAuthorization`). |
| `NetworkConfig.apiBaseURL(for:)` | `Core/Sources/Network/NetworkConfig.swift` | 버전마다 기본 URL을 만들어요. `https://poppang.co.kr/api/v1`, `https://poppang.co.kr/api/v2` |
| `APIResponse<T>`, `ErrorResponse` | `Core/Sources/Network/APIResponse.swift` | V2 성공 응답 래퍼와 V1·V2 공통 실패 응답 형식 |
| `asyncRequest(_:decodeDataTo:)` | `Core/Sources/Network/MoyaProvider+Async.swift` | `APIResponse`로 감싼 API만 이 함수로 요청하고 `data`를 돌려받아요. |
| `NetworkError.statusCode`, `serverErrorCode`, `isExpiredToken` | `Core/Sources/Network/NetworkError.swift` | 실패 본문에서 서버 에러 코드를 읽어요. 5xx 기본 오류 본문처럼 형식이 다르면 `serverErrorCode`는 `nil`이고, HTTP 상태로 처리해요. |
| `AuthTokenStorage` | `Core/Sources/LocalStorage/Storage/AuthToken/` | Access·Refresh·Signup Token을 UserDefaults(`UserDefaultsStore`)에 저장해요. 키는 `auth.accessToken`, `auth.refreshToken`, `auth.signupToken`이에요. 명세와 다른 결정이라 [정해야 할 것](#정해야-할-것) 8번에 이유를 적었어요. |
| `KeychainStoring`, `KeychainStore` | `Core/Sources/LocalStorage/Store/Keychain/` | Keychain 저장 구현이에요. 지금은 쓰지 않고 남겨 둬요. |
| `AccessTokenRefresher` | `Core/Sources/Network/Auth/AccessTokenRefresher.swift` | 만료된 Access Token을 갱신해요. 동시에 여러 요청이 만료돼도 갱신 요청은 하나만 보내요. |
| `AuthenticationPlugin` | `Core/Sources/Network/Auth/AuthenticationPlugin.swift` | V2 요청에 `Authorization` 헤더를 붙이는 Moya plugin이에요. `NetworkProvider(authentication:)`로 넣어요. |

### 토큰 처리 규칙

`AuthenticationPlugin`이 들어간 provider에서 `asyncRequest`는 아래처럼 동작해요.

| 상황 | 동작 |
| --- | --- |
| `access` API가 401 5002(만료)를 받아요. | 그 요청에 실제로 담았던 토큰을 기준으로 한 번 갱신하고, 새 토큰으로 원래 요청을 한 번만 다시 보내요. 다시 보낸 요청이 다시 5002를 받으면 받은 오류를 그대로 던지고 토큰은 지우지 않아요(명세가 정하지 않은 경우예요). 다시 보낸 요청이 5002가 아닌 401을 받으면 아래 줄처럼 처리해요. |
| 여러 요청이 동시에 만료돼요. | 갱신 요청은 하나만 보내요. 나머지 요청은 그 결과를 기다렸다가 새 토큰으로 다시 보내요. |
| `access` API가 5002가 아닌 401을 받아요. | 같은 토큰으로는 다시 성공할 수 없어서 Access·Refresh Token을 지우고 `AuthSessionError.loginRequired`를 던져요. 다만 요청을 보낸 뒤 다른 요청이 토큰을 갱신했으면 새 토큰은 지우지 않고, 새 토큰으로 원래 요청을 한 번만 다시 보내요. 토큰 없이 보낸 요청이면, 토큰 쌍이 없을 때 남은 토큰을 지우고 `loginRequired`를 던져요. 그사이 로그인으로 쌍이 생겼으면 새 토큰으로 한 번만 다시 보내요. |
| 토큰 쌍이 다 갖춰지지 않았어요 (Refresh Token만 남음 등). | 로그아웃 상태로 봐요. `removeIncompleteTokens()`가 lock 안에서 확인한 뒤 남은 토큰을 지워요. |
| 갱신 API가 401을 주거나 Refresh Token이 없어요. | 토큰을 지우고 `AuthSessionError.loginRequired`를 던져요. 지우다 실패해도 그 토큰은 더 쓸 수 없으므로 `loginRequired`를 던져요. |
| 갱신이 401이 아닌 이유로 실패해요 (400, 403, 429, 500, 503, 네트워크 오류). | 토큰을 그대로 두고, 원래 요청이 받은 401 5002 오류를 던져요. 다음 요청이 만료되면 다시 갱신해요. 이 정책은 [정해야 할 것](#정해야-할-것) 3번이 정해지면 다시 봐요. |
| 갱신하는 동안 로그아웃으로 토큰이 지워져요. | 늦게 온 응답을 저장하지 않고 `AuthSessionError.loginRequired`를 던져요. |
| 갱신하는 동안 다시 로그인해서 새 토큰이 저장돼요. | 늦게 온 응답(성공이든 401이든)으로 새 로그인 토큰을 덮어쓰거나 지우지 않고, 새 로그인의 Access Token을 써요. |
| 갱신한 토큰을 저장하지 못해요. | 서버는 이미 이전 Refresh Token을 폐기했으므로, 남은 옛 토큰을 지우고 `AuthSessionError.loginRequired`를 던져요. |
| 만료 응답을 받은 요청에 어떤 토큰을 담았는지 알 수 없어요. | 다른 요청이 갱신했다고 보지 않고 갱신해요. |
| 403을 받아요. | 갱신하지 않아요. |
| `signup` API가 401 5002를 받아요. | 갱신하지 않아요. Signup Token이 만료된 것이라 소셜 로그인부터 다시 해요. |
| V1 API | 헤더를 붙이지 않고, 401을 받아도 갱신하지 않아요. |

### 동시에 일어나는 토큰 변경

토큰 갱신, 로그아웃, 재로그인은 서로 다른 스레드에서 겹칠 수 있어요. `AuthTokenStorage`는 모든 동작을 lock 하나로 묶고, "저장된 토큰이 내가 쓴 토큰일 때만 바꾸거나 지우는" 동작을 한 번에 처리해요(`replaceTokens(_:ifRefreshTokenIs:)`, `removeTokens(ifAccessTokenIs:)`, `removeTokens(ifRefreshTokenIs:)`). 그래서 늦게 온 갱신 응답이 로그아웃으로 지운 토큰을 되살리거나, 옛 토큰으로 보낸 요청의 실패가 새 토큰을 지우지 않아요.

토큰 갱신과 재요청은 `MoyaProvider.asyncRequest(_:)` 안에서만 일어나요. V2 `access` API를 `provider.request`의 callback으로 직접 부르면 갱신되지 않으니, Repository는 지금처럼 `asyncRequest` 계열 함수만 써요. Alamofire `AuthenticationInterceptor`로 옮기면 모든 요청 경로에 적용되지만, 401 본문의 서버 코드(5002)로 갱신 여부를 나눠야 해서 이번에는 직접 구현했어요.

### V2 target 만들기

V2로 옮기는 target은 버전과 인증 종류를 정하고, 경로는 명세의 V2 경로에서 `/api/v2`를 뺀 값을 써요.

```swift
extension UserAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }
}
```

case마다 인증 종류가 다르면 `switch`로 나눠요. 응답이 `APIResponse`로 감싸진 API는 `asyncRequest(_:decodeDataTo:)`로, 감싸지 않은 API는 지금처럼 `asyncRequest(_:decodeTo:)`로 요청해요. 성공 본문이 없거나 `data`가 늘 null인 API(`ApiResponse[null]`)는 `asyncRequestVoid(_:)`로 요청해요.

### 2단계에서 연결한 것

- `NetworkProvider.shared`에 `AuthenticationPlugin`을 넣는 일과 갱신 API target은 2단계에서 했어요. [2단계](#2단계-로그인-모듈과-유저-엔티티)를 봐요.

## 2단계: 로그인 모듈과 유저 엔티티

로그인·가입·앱 시작 세션 복구·로그아웃을 V2로 옮기고, 카카오·애플·구글 로그인을 전략 패턴으로 묶었어요. PR 하나로 해요(#118).

### 구조

소셜 로그인은 "SDK로 증명 값을 받는 단계"만 제공자마다 다르고, "그 값을 서버에 보내는 단계"는 같아요. 다른 부분은 전략으로, 같은 부분은 Repository 하나로 나눴어요.

| 구성 요소 | 위치 | 역할 |
| --- | --- | --- |
| `SocialLoginStrategy` | `Data/Sources/SocialLogin/` | `login() -> SocialCredential`. 제공자마다 SDK로 로그인하고 서버에 보낼 증명 값을 돌려줘요. 사용자가 창을 닫으면 `AuthError.cancelled`를 던져요. |
| `KakaoLoginStrategy` | 같음 | 카카오톡 앱이 있으면 앱으로, 없으면 카카오 계정 웹으로 로그인해 `access_token`을 받아요. |
| `GoogleLoginStrategy` | 같음 | `GIDSignIn`으로 `id_token`을 받아요. |
| `AppleLoginStrategy` | 같음 | `ASAuthorizationController`를 Data 안에서 직접 띄워요. 요청마다 nonce 원문을 만들고, Apple 요청에는 그 SHA-256 값(소문자 16진수)을 넣어요. 서버에는 `auth_code`와 원문(`raw_nonce`)을 보내요. |
| `AuthRepositoryImpl` | `Data/Sources/RepositoryImpl/` | 모든 제공자에 같은 서버 단계예요. V2 로그인·가입·내 정보 조회·로그아웃을 부르고 토큰을 `AuthTokenStorage`에 저장해요. 토큰은 feature에 넘기지 않아요. 서버 오류 코드는 `AuthError`로 바꿔요. |
| `AuthAPI`, `AuthTokenRefreshAPI` | `Data/Sources/Remote/Auth/` | V2 인증 API target. 갱신 API는 인증 plugin이 없는 provider로 불러서 갱신 요청에 다시 갱신이 걸리지 않아요. |
| `Provider`, `Role`, `LoginResult`, `SignupRequest`, `AuthError`, `AuthRepositoryProtocol`, `AuthUsecase` | `Domain` | `LoginResult`는 `.completed(User)` 또는 `.pending(Provider)`예요. |
| `User` | `Domain/Sources/Entities/User.swift` | V2 사용자 정보 모양이에요. `uid`·`fcmToken`·`alertKeywordList`·`recommendList`를 뺐고, `provider`·`role`은 enum이에요. 관리자 판단은 `isAdmin`으로 해요. |

새 제공자를 추가하려면 `SocialLoginStrategy`를 채택한 전략 하나를 만들고 `AuthRepositoryImpl` 기본 목록에 넣어요.

### 흐름

1. 로그인 버튼 3개가 같은 action(`loginTapped(Provider)`)을 보내요.
2. COMPLETED이면 토큰 쌍을 저장하고 메인으로, PENDING이면 가입 전용 토큰을 저장하고 가입 화면으로 가요.
3. 가입은 가입 전용 토큰으로 요청하고 본문에 `"signupOs": "IOS"`를 넣어요. 성공하면 토큰 쌍을 저장하고 가입 전용 토큰을 지워요. 가입 단계가 만료됐거나(401 5002·5014 등) 탈퇴한 계정(401 5010)이면 안내와 함께 로그인 화면으로 돌아가요. 닉네임이 중복이면(409 4202) 닉네임 단계로 돌아가요.
4. 앱 시작은 `autoLogin` 대신 저장된 토큰으로 내 정보 조회(`GET /api/v2/user`)를 불러 세션을 되살려요. 아직 V1인 API를 위해 받은 `userUuid`를 저장해요.
5. 로그아웃은 기기의 토큰과 세션을 지우고 서버 로그아웃(`POST /api/v2/auth/logout`)을 알려요.
6. 앱을 쓰는 중에 `AuthSessionError.loginRequired`가 나면 `AuthenticationPlugin`이 `AuthSessionEvents`로 알리고, `AppFeature`가 메인 화면에서만 로그아웃 전환을 해요. 화면 전환용 closure 대신 구독할 때마다 새 stream을 주는 알림 객체를 써요.
7. 로그아웃은 로컬 세션과 기기 토큰을 먼저 지우고, 미리 꺼내 둔 Access Token을 헤더에 직접 담아 서버 로그아웃을 보내요. 그래서 기다리는 동안 다시 로그인해도 새 토큰이 지워지지 않고, Access Token이 만료됐어도 갱신된 토큰이 기기에 남는 일이 없어요. 로그아웃 요청이 401 5002(만료)를 받으면 꺼내 둔 Refresh Token으로 한 번 갱신해 그 Access Token으로 다시 보내요. 서버의 Refresh 세션을 지우기 위해서예요. 갱신한 토큰은 저장하지 않아요.

`AppBootstrap`이 토큰 저장소, refresher, 인증 plugin을 만들어 `NetworkProvider.shared.configureAuthentication(_:)`으로 요청 전에 연결해요.

### 2단계에서 정한 것

| 상황 | 결정 |
| --- | --- |
| 가입 화면의 추천 목록·닉네임 중복 확인 | 서버가 두 V2 API를 Signup Token으로 부를 수 있게 권한을 바꿔서, 가입 화면은 `GET /api/v2/recommend`와 `GET /api/v2/user/nickname/duplicated`를 Signup Token으로 불러요(`AuthAPI.signupRecommendList`, `.signupNicknameDuplicated`). 가입 단계가 만료되면(401 5002·5014·5006) 로그인 화면으로 돌아가요. 프로필 화면의 닉네임 중복 확인은 Access Token으로 3단계에서 옮겨요. ([정해야 할 것](#정해야-할-것) 1번) |
| 기존 사용자 | 업데이트 뒤 한 번 다시 로그인해요. |
| 서버 로그아웃 실패 | 기기의 토큰과 세션은 지우고 로그아웃해요. 서버 세션은 남을 수 있어요. |
| 앱 시작 때 내 정보 조회가 서버 오류·네트워크로 실패 | 토큰은 지우지 않고 로그인 화면을 보여 줘요. 다음 실행 때 다시 확인해요. |
| 가입 도중 앱을 다시 켬 | 가입 전용 토큰을 지우고 로그인부터 다시 해요. |
| 로그인 실패 안내 | 탈퇴 계정(5010), 다른 방식으로 가입된 계정(5016), 그 밖의 실패 세 가지로 안내해요(ko·en·ja). 사용자가 창을 닫으면 안내하지 않아요. |
| 애플 로그인 요청 범위 | 이전처럼 이름·이메일 범위(scope)를 요청하지 않아요. |

### 직접 확인할 것

- 제공자마다 신규 가입(PENDING)과 기존 로그인(COMPLETED)
- 앱을 다시 켰을 때 로그인 유지, 로그아웃
- 애플 로그인은 실제 기기에서 확인해요. nonce 형식이 틀리면 401 5015로 실패해요.

## 3단계: 내 정보

프로필 화면이 부르는 사용자 API 4개를 먼저 옮겼어요(#120). FCM 토큰 등록(USER-06)은 다음 PR에서 옮겨요.

### 프로필 화면

| 기능 | V1 | V2 | 성공 응답 |
| --- | --- | --- | --- |
| 닉네임 중복 확인 (USER-04) | `GET /api/v1/user/nickname/duplicated` | `GET /api/v2/user/nickname/duplicated` | `APIResponse`로 감싼 `{ isDuplicated }` |
| 닉네임 변경 (USER-02) | `PATCH /api/v1/user/{userUuid}` | `PATCH /api/v2/user` | 빈 본문 |
| 알림 켜기·끄기 (USER-05) | `PATCH /api/v1/user/{userUuid}/alert-status` | `PATCH /api/v2/user/alert-status` | `APIResponse`로 감싼 `{ userUuid, isAlerted }` |
| 회원 탈퇴 (USER-03) | `DELETE /api/v1/user/{userUuid}/hard-delete` | `DELETE /api/v2/user` | 빈 본문 |

- 모두 Access Token으로 부르고 경로에 `userUuid`를 넣지 않아요. 요청은 `Data/Sources/Remote/V2UserAPI.swift`에 있고, `UserRepositoryImpl`이 불러요.
- `UserRepositoryProtocol`·`UserUsecase`·`ProfileFeatureClient`의 해당 함수에서 `userUuid` 인자를 뺐어요. 탈퇴 함수 이름은 `hardDeleteUser`에서 `withdraw`로 바꿨어요. 프로필 화면 state도 `userUuid`를 들고 있지 않아요.
- 실패는 `UserError`로 바꿔요. 닉네임 중복(409 4202)은 `.duplicateNickname`, 빈 값이나 공백만 있는 닉네임(400 4205)은 `.invalidNickname`, 나머지는 `.failed`예요. 다시 로그인해야 하는 실패(`AuthSessionError`)는 바꾸지 않고 그대로 던져서, 프로필 화면이 실패 안내를 띄우지 않아요. 프로필 화면은 `ProfileErrorMessage`로 안내 문구를 골라요(ko·en·ja).
- 닉네임 변경이 중복으로 실패하면 입력란 아래 중복 안내를, 잘못된 값으로 실패하면 "사용 가능" 표시를 지우고 안내해요. 둘 다 다시 중복 확인을 해야 바꿀 수 있어요.
- 닉네임 확인·변경 응답에는 보낸 닉네임을 함께 실어요. 응답을 기다리는 동안 입력이 바뀌면 확인 결과를 새 입력에 붙이지 않고, 변경에 성공하면 실제로 보낸 닉네임을 홈 화면에 알려요. 입력이 바뀐 뒤 실패가 오면 확인 상태는 두고 바꾸지 못했다는 안내만 해요.
- 탈퇴 요청을 기다리는 동안(`isWithdrawing`)에는 탈퇴·로그아웃·뒤로가기 버튼을 막아요. 화면이 닫히면 탈퇴 effect가 취소돼 로그아웃 전환이 일어나지 않기 때문이에요. 화면 왼쪽 끝에서 밀어서 닫는 제스처는 DSKit이 앱 전체에 켜 둔 것이라 막지 않았어요.
- 알림 켜기·끄기는 응답의 `isAlerted`를 화면 상태에 반영해요.
- 탈퇴에 성공하면 기존 로그아웃 전환(`logoutRequested`)으로 보내고, 기기의 토큰은 그 전환이 지워요. Repository에서 먼저 지우면 아직 진행 중인 다른 요청이 토큰 없이 실패해 세션 만료 알림이 로그아웃 전환과 겹치기 때문이에요. 뒤이은 서버 로그아웃은 사용자가 없어 실패하지만, 로그아웃은 서버 응답과 관계없이 끝나요.
- 탈퇴 응답을 받지 못해 다시 보냈는데 사용자가 없다는 응답(404 4201)이 오면 이미 탈퇴한 것으로 봐요.

### 3단계에서 정한 것

| 상황 | 결정 |
| --- | --- |
| 회원 탈퇴 | 명세(`cc55e51`)의 V2 탈퇴는 탈퇴 표시만 해서(soft delete) 같은 소셜 계정으로 다시 가입할 수 없었어요. 서버가 V2 탈퇴를 영구 삭제로 바꿔 배포해서(2026-10-25), V1 영구 삭제처럼 탈퇴한 뒤 다시 가입할 수 있어요. 탈퇴 안내 문구("모든 데이터가 삭제되며 복구할 수 없습니다")는 그대로 둬요. 확인 필요: 바뀐 서버 명세나 서버 PR |
| 회원 복구 | V2에 없어요. 앱은 V1 복구(`resotre`)를 부르지 않아요. |

### 직접 확인할 것

- 프로필 화면에서 닉네임 중복 확인과 변경, 알림 켜기·끄기
- 테스트 계정으로 탈퇴한 뒤 같은 소셜 계정으로 다시 가입되는지

## 기존 사용자 데이터 보정

V2 가입은 가입 OS(`signupOs`)를 보내지만, 그 전에 가입한 사용자는 서버에 가입 OS가 비어 있어요. 서버가 이 값을 채우는 API를 마이그레이션 명세(`cc55e51`) 뒤에 추가했어요(2026-10-25).

| 항목 | 값 |
| --- | --- |
| API | `PATCH /api/v2/user/signup-os`, Access Token, 본문 `{"signupOs":"IOS"}`, 성공 응답은 빈 본문 |
| 인증 | 시작할 때 꺼낸 Access Token을 헤더에 직접 담아요. 인증 plugin의 갱신·재시도를 거치지 않아요. |
| 서버 동작 | 가입 OS가 비어 있으면 저장하고, 이미 값이 있으면 유지해요. |
| 부르는 때 | 자동 로그인이나 로그인 완료로 메인 화면에 들어갈 때(`AppFeature`). 신규 가입은 가입 요청이 가입 OS를 보내서 부르지 않아요. |

| 구성 요소 | 위치 | 역할 |
| --- | --- | --- |
| `MigrationUsecase` | `Domain` | 이 사용자에게 아직 하지 않은 마이그레이션을 실행하고, 성공한 것만 기록해요. |
| `MigrationRepositoryProtocol` | `Domain` | 서버 요청과 기기의 완료 기록을 맡아요. |
| `MigrationAPI`, `MigrationRepositoryImpl` | `Data` | 요청을 보내고, 마친 사용자 UUID를 UserDefaults(`migration.signupOsFilledUsers`)에 기록해요. |
| `AppMigrationClient` | `App` | `AppFeature`가 부르는 TCA 의존성이에요. 실패하면 로그만 남겨요. |

- 기록은 사용자별이라, 한 기기에서 다른 계정으로 로그인하면 그 계정에서 한 번 더 보내요.
- 요청은 그때의 Access Token으로 나가요. 그래서 로그아웃하면(`sessionExpired` 포함) 진행 중인 마이그레이션을 취소해요. 요청 전후로 취소를 확인해서, 취소됐으면 보내지 않거나 완료로 기록하지 않아요.
- 이미 보낸 요청 자체는 멈추지 않아요(`MoyaProvider.asyncRequest`가 취소를 네트워크 요청에 전하지 않아요). 그래서 토큰 갱신 뒤 다시 보내는 일이 없게, 로그아웃 요청처럼 시작할 때의 Access Token을 헤더에 직접 담아요. 요청은 늘 처음 사용자의 토큰으로만 나가요. 토큰이 만료돼 실패하면(401 5002) 기록하지 않고 다음 실행 때 다시 해요. 자동 로그인은 내 정보 조회에서 토큰을 갱신한 뒤라 보통 만료되지 않아요.
- 신규 가입한 사용자는 완료로 기록하지 않아서, 다음 실행 때 한 번 보내요. 서버가 이미 있는 값을 유지해요.
- 확인 필요: Android로 가입했지만 서버에 가입 OS가 비어 있는 사용자가 iOS 앱을 처음 열면 IOS로 채워져요. 서버 설계대로예요.
- 실패하면 기록하지 않아서 다음 실행 때 다시 보내요. 화면에는 알리지 않고 메인 화면은 그대로 들어가요.
- 기록은 앱을 지우면 함께 지워져요. 다시 설치해 한 번 더 보내도 서버가 이미 있는 값을 유지해요.
- 사용자 엔티티(`User`)에는 가입 OS를 넣지 않았어요. V2 내 정보 응답에 없고, 채울지는 서버가 판단해요.
- 새 마이그레이션이 생기면 `MigrationRepositoryProtocol`에 요청과 기록 함수를, `MigrationUsecaseImpl.runPendingMigrations`에 실행 단계를 더해요.

## 남은 작업: feature별 전환

3단계(프로필) 이후에는 명세 묶음 대신 **화면(feature) 단위**로 옮겨요. PR도 feature마다 하나씩 올려요.

| 순서 | feature | 옮길 V1 API (명세) | 상태 |
| --- | --- | --- | --- |
| 1 | SearchFeature | 회원 팝업 검색 (UPOP-11) | 완료 (#131) |
| 2 | FavoritesFeature | 찜 목록 (FAV-04), 찜 등록·해제 (FAV-01·02) | 진행 중 (#132) |
| 3 | PopupDetailFeature | 조회수 기록 (POP-14), 관련 팝업 (UPOP-03), 찜 등록·해제 | 예정 |
| 4 | CalendarFeature | 필터 팝업 (UPOP-04), 지역 목록 (POP-10), 찜 등록·해제 | 예정 |
| 5 | HomeFeatureV2 | 오픈 예정 (UPOP-12), 필터 팝업, 랜덤 (UPOP-07), 지역 목록, 찜 등록·해제 | 예정 |
| 6 | MapFeature | 지도 필터 (UPOP-05), 인기 추천 카테고리 (RECO-02), 카테고리별 팝업 (UPOP-09), 지역 목록, 찜 등록·해제 | 예정 |
| 7 | AlertFeature | 알림 키워드 목록·등록·삭제 (ALERT-01~03), 알림함 목록·삭제 (ALERT-04·05), 찜 등록·해제 | 예정 |
| 8 | App (푸시) | FCM 토큰 중복 확인·갱신 두 요청을 `PUT /api/v2/user/fcm-token` 하나로 (USER-06) | 예정 |
| 9 | 정리 | 쓰지 않는 V1 case(비회원 팝업 목록 등), Repository·Usecase의 `userUuid` 인자, 세션의 `userUuid` 저장 | 예정 |

- 여러 feature가 같이 쓰는 API(찜 등록·해제, 지역 목록, 필터 팝업)는 **처음 쓰는 feature에서 V2로 만들고**, 뒤의 feature는 가져다 써요. 옮기는 동안 화면마다 V1·V2가 섞여도 서버 데이터가 같아서 괜찮아요(명세 C-9).
- 회원 팝업 V2 API는 `Data/Sources/Remote/V2PopupAPI.swift`에 모아요. 응답은 V1과 같은 감싸지 않은 팝업 배열이라 `PopupDTO`를 그대로 써요.
- 찜 V2 API는 경로(`/favorite`)가 달라 `Data/Sources/Remote/V2FavoriteAPI.swift`에 따로 둬요. 찜 목록은 검색과 달리 `APIResponse`로 감싼 팝업 배열이에요. 등록·해제는 본문에 `popupUuid`만 담고, DELETE도 JSON 본문을 보내요.
- 찜 등록·해제 V2는 `PopupUsecaseProtocol`의 `addFavorite(popupUuid:)`·`removeFavorite(popupUuid:)`예요(#132). 3번부터의 화면은 기존 `addFavorite(userUuid:popupUuid:)` 대신 이 함수를 가져다 써요. 기존 함수는 모든 화면이 옮긴 뒤 9번 정리 단계에서 지워요.
- V2 팝업·찜 요청이 실패하면 Repository가 `PopupError.failed`로 바꾸고, 화면은 원본 오류 대신 안내 문구를 보여 줘요. 이미 찜함(409 4101)·찜 없음(404 4102)도 성공으로 보지 않아요. 찜 탭은 하트를 누르면 응답을 기다리지 않고 목록에서 먼저 빼고, 실패하면 목록을 다시 받아 서버 상태로 되돌려요. 로그인이 끊긴 실패는 다시 받지 않아요.
- `PopupDTO`는 명세상 null일 수 있는 `roadAddress`·`mediaType`·`recommendList`를 null로 받아요. null이면 각각 일반 주소(`address`)·이미지·빈 배열로 바꿔요. 도로명 주소가 빈 문자열이어도 일반 주소를 써요. 전에는 null을 받으면 목록 전체를 읽지 못했어요(V1부터 있던 문제, #130에서 수정).
- `userUuid`는 아직 V1인 화면이 쓰므로 마지막 정리 단계에서 지워요. 예를 들어 검색 결과에서 여는 팝업 상세는 V1이라, `SearchDestination`이 `userUuid`를 들고 있다가 상세에 넘겨요.

**확인 필요 (백엔드)**
- 팝업 상세의 관리자 팝업 비활성화(`/api/v1/admin/popup/{popupUuid}/deactivate`)를 앱이 직접 불러요. 명세에서 Admin API는 범위 밖이에요.
- 팝업 제보(SUB-01)는 Swift 코드에서 부르지 않아요. React Native 화면이 직접 부르는지 PopPang-RN 저장소에서 확인해야 해요.

헬스 체크(`GET /api/v1/health`)는 대응 V2가 없어서 V1 그대로 써요.

## 정해야 할 것

| 번호 | 내용 | 관련 단계 | 상태 |
| --- | --- | --- | --- |
| 1 | 가입 화면이 추천 카테고리 목록과 닉네임 중복 확인을 인증 없이 불러요. V2에서는 Signup Token으로 두 API를 부를 수 없어요. 당분간 V1로 둘지, 서버 계약을 정할지 | 2, 3, 5 | 해결함 (2026-10-21). 서버가 두 API를 Signup Token으로도 부를 수 있게 권한을 바꾸기로 했어요. 확인 필요: 운영 서버 반영 여부. 반영 전이면 가입 화면 요청이 403 5008로 실패해요. |
| 2 | 업데이트하면 기존 사용자는 V2 토큰이 없어서 한 번 다시 로그인해야 해요. 그대로 받아들일지 | 2 | 받아들이기로 결정함 |
| 3 | 토큰 갱신이 401이 아닌 이유로 실패할 때 토큰을 지울지, 언제 다시 시도할지. 1단계는 토큰을 그대로 둬요. | 1, 2 | 미정 |
| 4 | 서버 로그아웃이 실패할 때 로컬 로그인 정보를 지울지 | 2 | 지우기로 결정함 |
| 5 | 가입 OS 기록. 명세(`cc55e51`)의 V2 가입은 `signupOs`를 받지 않았어요. | 2 | 해결함 (2026-10-21). 서버가 V2 가입에 `signupOs`를 추가해 배포했어요. 앱은 가입 요청 본문에 항상 `"signupOs": "IOS"`를 보내요(`V2SignupRequestDTO`). |
| 6 | 로그인 전 화면이 부르는 V1 조회 API가 있는지 | 4 | 해결함 (2026-10-27). 온보딩 화면은 API를 부르지 않고, 로그인 화면은 V2 인증 API만 불러요. 팝업 조회는 모두 메인 탭 안에서만 일어나요. |
| 7 | 토큰 유효기간과 요청 제한 횟수의 운영 값. 앱에 하드코딩하지 않아요. | 2 | 확인 필요: 서버 운영 설정 |
| 8 | 토큰 저장 위치. 명세는 iOS Keychain에만 두라고 해요. 하지만 Keychain 항목은 앱을 지워도 남아서, 재설치 뒤 이전 계정 토큰이 요청에 실릴 수 있어요. 그래서 앱을 지우면 함께 지워지는 UserDefaults에 두기로 했어요. 대신 UserDefaults는 암호화되지 않은 파일이라 기기 백업이나 탈옥 기기에서 토큰이 보일 수 있어요. `KeychainStore` 구현은 남겨 둬서 나중에 다시 바꿀 수 있어요. | 1 | 결정함 (2026-10-19) |

## 관련 문서

- [아키텍처](architecture.md)
- [의존성 주입](dependency-injection.md)
- [테스트](../development/testing.md)
