# PopPang React Native 패키지

이 문서는 팝업 제보 화면에 쓰는 React Native(RN) Swift Package를 앱에 연결하는 방법과 버전을 바꾸는 방법을 정리한다. RN 버전을 바꾸거나 RN 화면과 앱 사이의 연결을 고칠 때 읽는다.

## 개요

| 항목 | 값 |
| --- | --- |
| RN 저장소 | [`team-PopPang/PopPang-RN`](https://github.com/team-PopPang/PopPang-RN) (우리 팀 저장소, 공개) |
| 배포 도구 | [Nativepiece](https://github.com/team-PopPang/Nativepiece). RN 앱을 Swift Package 하나로 만들어 RN 저장소에 태그와 GitHub Release로 배포한다. |
| 앱이 쓰는 버전 | `1.4.0` (Nativepiece로 만든 첫 버전. 제보·제보 관리 화면이 V2 API와 앱의 Access Token을 쓴다) |
| 앱에서 쓰는 곳 | `PopPangRNFeature` 모듈의 팝업 제보(`popupRequest`), 팝업 제보 관리(`popupRequestManagement`) 화면 |
| 받는 방법 | Xcode가 `tuist generate` 뒤 빌드할 때 Swift Package로 받는다. 따로 실행할 스크립트는 없다. |

Swift Package에는 React Native·Hermes·네이티브 모듈 XCFramework(GitHub Release의 zip), 호스트 SDK `NativepieceKit`, JS 번들(`ReactNative/main.jsbundle`)과 이미지, 계약에서 만든 Swift 타입(`PopPangRN.Screen`, `PopPangRN.Event`, `PopPangRNHost`)이 들어 있다. 앱 저장소는 RN 프로젝트와 CocoaPods를 품지 않는다.

## 앱 manifest에서 연결되는 곳

| 파일 | 연결 |
| --- | --- |
| `Projects/Features/PopPangRNFeature/Project.swift` | `packages: [.remote(url: "https://github.com/team-PopPang/PopPang-RN", requirement: .exact("1.4.0"))]`, `.package(product: "PopPangRN")` |
| `Projects/App/Project.swift` | 같은 `.remote(...)`와 `.package(product: "PopPangRN")` |

- 앱 target과 `PopPangRNFeature` 두 곳에 연결한다. 두 target이 함께 쓰면 Xcode가 product를 동적 framework 하나(`PopPangRN_…_PackageProduct.framework`)로 만들어 코드가 한 번만 들어가고, 패키지의 동적 XCFramework(`React`, `hermesvm`, `ReactNativeDependencies`)도 앱 `Frameworks/`에 들어간다.
- `PopPangRNFeature`(`.framework`)에만 연결하면 이 framework들이 앱에 들어가지 않아 실행하자마자 `Library not loaded: @rpath/React.framework/React`로 종료된다. Nativepiece README도 모듈 제품을 앱 target에 추가하라고 안내한다.
- 버전을 바꿀 때는 두 `Project.swift`의 `.exact(...)`를 함께 바꾼다.
- JS 번들은 패키지 리소스(`PopPangRN_PopPangRN.bundle/ReactNative/main.jsbundle`)로 앱에 들어간다. 앱의 `Resources`에 번들을 두지 않는다.
- RN 저장소가 공개라서 `~/.netrc` 토큰 없이 받는다. CI도 따로 받는 단계가 없다.

## 앱에서 RN 화면을 여는 방식

| 구성 요소 | 위치 | 하는 일 |
| --- | --- | --- |
| `PopPangRNRuntime` | `PopPangRNFeature/Sources/Support/PopPangRNRuntime.swift` | `start(authentication:)`이 `PopPangRN.start(host:prewarm:)`로 런타임을 시작하고, 계약의 `getAccessToken` 요청을 `AuthenticationPlugin.hostAccessToken(rejected:expired:)`로 처리한다. 런타임은 미리 띄우지 않고(`prewarm: false`) 화면을 처음 열 때 번들을 불러온다. Nativepiece 런타임은 앱 전체에 하나라 TCA `DependencyValues`가 아니라 앱 시작 때 한 번 연결한다. |
| `AppBootstrap.live()` | `App/Sources/AppCore/2. AppBootstrap.swift` | 앱을 시작할 때 한 번 `PopPangRNRuntime.start(authentication:)`을 부른다. 앱 요청과 같은 `AuthenticationPlugin`을 넘긴다. |
| `PopPangRNFeature` | `Sources/Presentation/PopPangRNFeature.swift` | `Screen`과 `userUuid`를 state로 갖고, RN 이벤트를 delegate로 바꾼다. |
| `PopPangRNFeatureView` | `Sources/Presentation/PopPangRNFeatureView.swift` | `NativepieceView(PopPangRN.Screen)`로 화면을 띄우고 `.onEvent`·`.onClose`를 reducer action으로 보낸다. |

화면을 열 때 넘기는 값(`PopPangRN.PopPangScreenProps`):

| 키 | 값 |
| --- | --- |
| `userUuid` | 로그인한 사용자의 UUID. RN은 입력 검증에만 쓰고 서버에는 보내지 않는다(V2는 Access Token으로 사용자를 정한다). |

RN 이벤트 처리:

| 화면 | RN이 보내는 것 | `PopPangRNFeature` action → delegate | `MainTabFeature`의 처리 |
| --- | --- | --- | --- |
| 팝업 제보 | 제출 완료 이벤트 `popupRequestSubmitted` | `.popupRequestSubmitted` → `.dismiss` | `destination`(fullScreenCover)을 닫는다. |
| 팝업 제보 | 뒤로가기(Nativepiece 표준 닫기 `host.close`) | `.closeRequested` → `.dismiss` | `destination`을 닫는다. |
| 팝업 제보 관리 | 뒤로가기(`host.close`) | `.closeRequested` → `.pop` | `path`에서 화면을 뺀다. |

`.onClose`를 지정하면 Nativepiece의 기본 닫기(dismiss·pop)는 동작하지 않는다. 화면 전환은 [TCA Navigation](../architecture/tca-navigation.md)대로 parent가 state로 한다.

Access Token 요청(`calls.getAccessToken`)의 규칙은 [V2 API 마이그레이션](../architecture/api-v2-migration.md#react-native-제보-화면-154)을 본다. 토큰을 주지 못하면 `NativepieceCallError`의 code로 답한다.

| code | 언제 | RN이 보여 주는 안내 |
| --- | --- | --- |
| `login_required` | 다시 로그인해야 한다. 앱은 로그인 화면으로 보낸다. | 로그인 정보가 만료되었습니다. 다시 로그인해 주세요. |
| `temporary_failure` | 토큰 갱신이 네트워크·서버 문제로 실패했다. 토큰은 그대로다. | 로그인 정보를 잠시 확인하지 못했습니다. 잠시 후 다시 시도해 주세요. |
| `unhandled` (Nativepiece가 보냄) | 앱이 `PopPangRNRuntime.start`를 부르지 않아 처리기가 없다. | 로그인 정보를 확인할 수 없습니다. 앱을 최신 버전으로 업데이트해 주세요. |

## 새 RN 버전 반영

1. RN 저장소에서 화면을 고치고 `package.json`의 `version`을 올려 main에 머지한 뒤, main에서 `npx nativepiece build ios && npx nativepiece publish ios`로 배포한다. 배포는 RN 저장소의 일이며 사용자가 요청할 때만 한다. 태그는 `1.4.0`처럼 `v` 없이 붙는다.
2. 앱 저장소에서 `Projects/App/Project.swift`와 `Projects/Features/PopPangRNFeature/Project.swift`의 `.exact("<버전>")`, 이 문서의 버전을 함께 바꾼다. 이 변경은 의존성 변경이므로 계획에 적고 승인을 받는다.
3. `tuist generate`로 workspace를 다시 만들고 빌드한다. Xcode가 새 버전을 받는다.
4. 계약(`nativepiece.contract.ts`)이 바뀌었으면 생성된 타입이 바뀌므로 `PopPangRNFeatureView`와 `PopPangRNRuntime`이 컴파일되는지 확인한다.
5. 앱에서 팝업 제보와 제보 관리 화면을 열어 확인한다.

RN 화면 자체의 수정은 RN 저장소에서 한다. 앱 저장소에 RN 소스를 복사하거나 패키지의 번들을 직접 고치지 않는다.

## 문제 해결

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| 앱이 실행하자마자 `Library not loaded: @rpath/React.framework/React`로 종료된다. | 앱 target에 `PopPangRN`이 연결되어 있지 않아 RN 동적 framework가 앱에 들어가지 않았다. | `Projects/App/Project.swift`에 패키지와 `.package(product: "PopPangRN")`이 있는지 확인한다. |
| 빌드 전에 `PopPangRN` 패키지를 받지 못한다. | 네트워크 문제이거나 Xcode 패키지 캐시가 깨졌다. | Xcode의 File → Packages → Reset Package Caches 후 다시 빌드한다. |
| RN 화면이 비어 있고 번들을 찾지 못했다는 로그가 남는다. | 패키지에 `ReactNative/main.jsbundle`이 없다. `1.3.0`은 RN 저장소의 `.gitignore`(`*.jsbundle`) 때문에 번들이 빠진 채 배포됐다. | `1.4.0` 이상을 쓴다. 새 버전을 받기 전에 태그에 `swift-package/PopPangRN/ReactNative/main.jsbundle`이 있는지 확인한다. |
| 제보 화면에서 "로그인 정보를 확인할 수 없습니다. 앱을 최신 버전으로 업데이트해 주세요."가 뜬다. | `getAccessToken` 처리기가 없다(`unhandled`). | `AppBootstrap.live()`가 `PopPangRNRuntime.start(authentication:)`을 부르는지 확인한다. |
| `cannot find type 'PopPangRNHost'`처럼 생성 타입을 찾지 못한다. | 계약이 바뀐 버전을 받았거나 패키지를 받지 못했다. | 버전의 `swift-package/PopPangRN/PopPangRNContract.swift`를 확인하고 앱 코드를 맞춘다. |

## 에이전트 작업 규칙

- RN 패키지 버전 변경은 의존성 변경이다. 계획에 적고 승인을 받는다.
- RN 저장소의 배포(`nativepiece publish`)는 사용자가 요청할 때만 한다.

## 관련 문서

- [Tuist 설치와 실행](tuist.md)
- [TCA Navigation](../architecture/tca-navigation.md)
- [모듈 구조](../architecture/modules.md)
- [V2 API 마이그레이션](../architecture/api-v2-migration.md)
