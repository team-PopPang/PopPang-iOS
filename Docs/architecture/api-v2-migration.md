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
| 1 | 공통 네트워크 기반 | COMMON | 없음 | 진행 중 (#116) |
| 2 | 로그인 모듈과 유저 엔티티 | A1, A2, USER-01 | 있음 (기존 사용자 재로그인) | 예정 |
| 3 | 내 정보 | U | 일부 | 예정 |
| 4 | 팝업 목록·상세 | P1, P2 | 거의 없음 | 예정 |
| 5 | 찜·추천 카테고리·팝업 제보 | F | 거의 없음 | 예정 |
| 6 | 알림 키워드·알림함 | K | 거의 없음 | 예정 |
| 7 | 회원 팝업과 V1 정리 | P3 | 없음 | 예정 |

- 1단계와 2단계는 순서대로 해요. 2단계는 1단계의 토큰 처리를 쓰고, 나머지 단계는 2단계가 저장한 Access Token을 써요.
- 3~7단계는 서로 의존하지 않아서 순서를 바꿔도 돼요.
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
| `signup` API가 401 5002를 받아요. | 갱신하지 않아요. Signup Token이 만료된 것이라 소셜 로그인부터 다시 해요(2단계에서 처리). |
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

### 2단계로 넘기는 일

- `NetworkProvider.shared`에 `AuthenticationPlugin`을 넣는 일. 갱신 API target(`POST /api/v2/auth/refresh`)이 `Data`에 생겨야 `AccessTokenRefresher`의 갱신 함수를 만들 수 있어서, 2단계에서 `AppBootstrap`이 조립해요.
- `AuthSessionError.loginRequired`를 받았을 때 로그인 화면으로 보내는 일
- 앱에서 토큰 저장·삭제를 실제로 확인하는 일

## 2단계: 로그인 모듈과 유저 엔티티

### 지금 구조

- `User`·`UserDTO`를 로그인 응답과 가입 요청에 같이 써요. `uid`, `fcmToken`, `alertKeywordList`, `recommendList`가 들어 있어요.
- 가입 화면은 로그인 응답의 `User`를 받아 시작하고(`AppFeature`의 `.register`), 그 `User`에 입력값을 채워 가입 요청을 보내요(`RegisterFlowFeature`).
- 앱을 시작하면 UserDefaults의 `uuid`로 `POST /api/v1/auth/autoLogin`을 불러 세션을 되살려요(`LocalSessionClient`).
- 로그아웃은 서버를 부르지 않고 로컬 세션만 지워요.
- 애플 로그인 요청에 nonce를 넣지 않아요(`AuthFeatureView`의 `SignInWithAppleButton`).

### V2에서 달라지는 것

- 로그인 응답이 가입 상태에 따라 둘로 나뉘어요. 가입을 마친 사용자(COMPLETED)는 사용자 정보와 토큰 쌍을 받고, 가입이 필요한 사용자(PENDING)는 Signup Token만 받아요. PENDING에는 사용자 정보가 없어요.
- V2 사용자 정보에는 `uid`와 `fcmToken`이 없어요.
- 가입 요청은 `uid`·`provider`·`email`·`role` 없이 Signup Token으로 대상을 정해요.
- 토큰 갱신 응답에는 사용자 정보가 없어요. 앱을 시작할 때 프로필은 내 정보 조회(USER-01)로 받아요.
- 애플 로그인은 요청마다 새 nonce를 만들어 Apple 요청에 SHA-256 값을 넣고, 서버에는 원문을 `raw_nonce`로 보내요.

### 바꿀 모델

| 모델 | 바뀌는 점 |
| --- | --- |
| `User` | V2 사용자 정보 모양으로 바꿔요. `uid`·`fcmToken`을 빼고 `provider`·`role`은 값이 없을 수 있는 enum으로 바꿔요. |
| `LoginResult` (새 entity) | `.completed(User)` 또는 `.pending(provider)`. 토큰은 Data가 `AuthTokenStorage`에 저장하고 feature에는 넘기지 않아요. |
| `SignupRequest` (새 entity) | 가입 입력값을 `User`와 분리해요. nickname, isAlerted, fcmToken, alertKeywordList, recommendList |

### 흐름

1. 로그인: PENDING이면 Signup Token을 저장하고 가입 화면으로 가요. COMPLETED이면 토큰 쌍을 저장하고 메인으로 가요.
2. 가입: Signup Token으로 요청하고, 성공하면 토큰 쌍을 저장하고 Signup Token을 지워요. 같은 provider의 로그인과 가입은 함께 옮겨요.
3. 앱 시작: `autoLogin`을 없애고, 저장된 토큰으로 내 정보 조회를 불러 세션을 되살려요. 토큰이 없으면 로그인 화면으로 가요.
4. 로그아웃: 서버 로그아웃(`POST /api/v2/auth/logout`)을 부른 뒤 토큰과 로컬 세션을 지워요.
5. 아직 V1인 API에는 COMPLETED 응답에서 저장한 `userUuid`를 그대로 넘겨요.

### PR 나누기

| PR | 내용 |
| --- | --- |
| 2-1 | 유저 entity, DTO, Repository·Usecase protocol 변경과 테스트 |
| 2-2 | `NetworkProvider.shared` 인증 연결, 카카오·애플·구글 로그인과 가입, 가입 화면 변경 |
| 2-3 | 앱 시작, 로그인 화면으로 보내는 처리, 로그아웃 |

## 3~7단계

| 단계 | 할 일 | 먼저 확인할 것 |
| --- | --- | --- |
| 3 (U) | 닉네임 변경, 탈퇴, 닉네임 중복 확인, 알림 설정, FCM 토큰 등록에서 `userUuid` 경로를 빼요. | 회원 영구 삭제와 회원 복구는 V2 대응 API가 없어요. 프로필 화면이 영구 삭제를 불러요(`ProfileFeatureClient`). |
| 4 (P1, P2) | 대부분 버전과 인증 종류만 바꿔요. 개인화 추천은 경로의 `userUuid`가 빠져요. | 로그인 전에 팝업 API를 부르는 화면이 있는지 |
| 5 (F) | 찜, 추천 카테고리, 팝업 제보 | 팝업 제보를 React Native 화면에서 보내는지 |
| 6 (K) | 알림 키워드, 알림함 | |
| 7 (P3) | 회원 팝업 API를 옮기고 V1 호출, `userUuid` 저장, `autoLogin` 잔재를 지워요. | 남은 V1 호출 목록 |

헬스 체크(`GET /api/v1/health`)는 대응 V2가 없어서 V1 그대로 써요.

## 정해야 할 것

| 번호 | 내용 | 관련 단계 | 상태 |
| --- | --- | --- | --- |
| 1 | 가입 화면이 추천 카테고리 목록과 닉네임 중복 확인을 인증 없이 불러요. V2에서는 Signup Token으로 두 API를 부를 수 없어요. 당분간 V1로 둘지, 서버 계약을 정할지 | 2, 3, 5 | 미정 |
| 2 | 업데이트하면 기존 사용자는 V2 토큰이 없어서 한 번 다시 로그인해야 해요. 그대로 받아들일지 | 2 | 미정 |
| 3 | 토큰 갱신이 401이 아닌 이유로 실패할 때 토큰을 지울지, 언제 다시 시도할지. 1단계는 토큰을 그대로 둬요. | 1, 2 | 미정 |
| 4 | 서버 로그아웃이 실패할 때 로컬 로그인 정보를 지울지 | 2 | 미정 |
| 5 | 지금 앱은 가입 요청에 `signupOs`를 보내지 않고, V2도 가입 OS를 저장하지 않아요. 가입 OS 통계가 필요한지 | 2 | 미정 |
| 6 | 로그인 전 화면이 부르는 V1 조회 API가 있는지 | 4 | 확인 필요: `OnboardingFeature`, `AuthFeature`의 client 호출 |
| 7 | 토큰 유효기간과 요청 제한 횟수의 운영 값. 앱에 하드코딩하지 않아요. | 2 | 확인 필요: 서버 운영 설정 |
| 8 | 토큰 저장 위치. 명세는 iOS Keychain에만 두라고 해요. 하지만 Keychain 항목은 앱을 지워도 남아서, 재설치 뒤 이전 계정 토큰이 요청에 실릴 수 있어요. 그래서 앱을 지우면 함께 지워지는 UserDefaults에 두기로 했어요. 대신 UserDefaults는 암호화되지 않은 파일이라 기기 백업이나 탈옥 기기에서 토큰이 보일 수 있어요. `KeychainStore` 구현은 남겨 둬서 나중에 다시 바꿀 수 있어요. | 1 | 결정함 (2026-10-19) |

## 관련 문서

- [아키텍처](architecture.md)
- [의존성 주입](dependency-injection.md)
- [테스트](../development/testing.md)
