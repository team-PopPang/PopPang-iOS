# PopPang React Native 산출물

이 문서는 팝업 제보 화면에 쓰는 React Native(RN) 산출물을 받고 앱에 연결하는 방법을 정리한다. 처음 workspace를 만들 때와 RN 버전을 바꿀 때 읽는다.

## 개요

| 항목 | 값 |
| --- | --- |
| RN 저장소 | [`team-PopPang/PopPang-RN`](https://github.com/team-PopPang/PopPang-RN) (우리 팀 저장소) |
| 앱이 쓰는 버전 | `v0.1.0` (2026-07-14 릴리즈, 2026-10-01 기준 유일한 릴리즈) |
| 앱에서 쓰는 곳 | `PopPangRNFeature` 모듈의 팝업 제보(`request`), 팝업 제보 관리(`request-management`) 화면 |
| 받는 방법 | `./scripts/download-rn-release.sh v0.1.0` |

RN 저장소는 React Native 런타임과 네이티브 의존성을 미리 빌드해 XCFramework로 묶어 배포한다(Prebuild 방식). 앱 저장소는 RN 프로젝트와 CocoaPods를 품지 않고, GitHub 릴리즈의 산출물만 받아 SPM local package로 붙인다.

## 산출물

| 릴리즈 파일 | 크기 (v0.1.0) | 내용 | 앱에 놓이는 위치 |
| --- | --- | --- | --- |
| `poppang-rn-ios-bundle-<버전>.zip` | 약 345KB | `main.jsbundle`, `assets/` | `Projects/App/Resources/ReactNative/` |
| `poppang-rn-spm-<버전>.zip` | 약 150MB | `PrebuiltReactNativeFrameworks` SPM 패키지 (XCFramework) | `Vendor/PrebuiltReactNativeFrameworks/` |

- 두 위치 모두 `.gitignore`에 들어 있다. 받은 산출물은 커밋하지 않는다.
- 릴리즈에는 Android용 파일(`poppang-rn-android-*`)도 있지만 iOS 앱은 받지 않는다.

앱 manifest에서 연결되는 곳:

| 파일 | 연결 |
| --- | --- |
| `Projects/App/Project.swift` | `packages: [.local(path: "../../Vendor/PrebuiltReactNativeFrameworks")]`, `.package(product: "PrebuiltReactNativeFrameworks")`, `resources`의 `.folderReference(path: "Resources/ReactNative")` |
| `Projects/Features/PopPangRNFeature/Project.swift` | `packages: [.local(path: "../../../Vendor/PrebuiltReactNativeFrameworks")]`, `.package(product: "PrebuiltReactNativeFrameworks")` |

## 받기

### 준비

- `gh auth login`으로 GitHub CLI에 로그인되어 있어야 한다. 스크립트가 `gh release download`로 받는다.
- 저장소 루트에서 실행한다.

### 실행

```bash
./scripts/download-rn-release.sh v0.1.0
```

버전을 생략하면 `v0.1.0`을 받는다. 스크립트는 아래 순서로 동작한다.

1. `.rn-release-temp/`에 두 zip을 받는다.
2. 압축을 풀고 `main.jsbundle`과 `PrebuiltReactNativeFrameworks/Package.swift`가 있는지 확인한다. 없으면 실패한다.
3. 기존 `Projects/App/Resources/ReactNative/`와 `Vendor/PrebuiltReactNativeFrameworks/`를 지우고 새 산출물로 바꾼다.
4. 끝나면 `.rn-release-temp/`를 지운다.

성공하면 번들 위치와 프레임워크 위치를 출력한다. SPM zip이 150MB라 받는 데 시간이 걸린다.

### 받은 뒤

`Vendor/PrebuiltReactNativeFrameworks`가 없으면 `tuist install`과 `tuist generate`가 실패하므로, workspace를 만들기 전에 받는다. 순서는 [Tuist 설치와 실행](tuist.md#workspace-만들기)을 따른다.

## 앱에서 RN 화면을 여는 방식

| 구성 요소 | 위치 | 하는 일 |
| --- | --- | --- |
| `PopPangRNFeature` | `Sources/Presentation/PopPangRNFeature.swift` | `Screen`(`popupRequest` = `"request"`, `popupRequestManagement` = `"request-management"`)과 `userUuid`를 state로 갖고, RN에서 온 이벤트를 delegate로 바꾼다. |
| `PopPangRNFeatureView` | `Sources/Presentation/PopPangRNFeatureView.swift` | `ReactNativeScreen`에 `moduleName: "PopPangRNRoot"`와 `initialProperties`를 넘긴다. |
| `ReactNativeScreen` | `Sources/Support/ReactNativeScreen.swift` | `RCTReactNativeFactory`로 RN 화면을 만든다. 번들은 앱 번들의 `ReactNative/main.jsbundle`에서 읽는다. |

`initialProperties`:

| 키 | 값 |
| --- | --- |
| `feature` | `"request"` 또는 `"request-management"`. 다른 값을 넣으면 RN의 기본 root 화면이 열리므로 이 두 값만 쓴다. |
| `userUuid` | 로그인한 사용자의 UUID. 제보 관리에는 관리자 UUID를 쓴다. |
| `nativeEvents` | RN이 앱으로 보낼 이벤트 목록. 목록에서 빼면 RN 화면의 뒤로가기 버튼도 숨겨진다. |

RN 이벤트 처리:

| 화면 | 이벤트 | `PopPangRNFeature` delegate | `MainTabFeature`의 처리 |
| --- | --- | --- | --- |
| 팝업 제보 | `popupRequestSubmitted`, `popupRequestBack` | `.dismiss` | `destination`(fullScreenCover)을 닫는다. |
| 팝업 제보 관리 | `popupRequestManagementBack` | `.pop` | `path`에서 화면을 뺀다. |

화면 전환 소유권은 [TCA Navigation](../architecture/tca-navigation.md)을 따른다.

## 새 RN 버전 반영

1. RN 저장소에서 화면을 고치고 `./scripts/release-rn.sh v<버전>`으로 릴리즈를 만든다. 릴리즈는 RN 저장소의 일이며 사용자가 요청할 때만 한다.
2. 앱 저장소에서 새 버전으로 받는다: `./scripts/download-rn-release.sh v<버전>`.
3. 앱에서 팝업 제보와 제보 관리 화면을 열어 확인한다.
4. 버전을 고정한 곳을 함께 바꾼다. 이 변경은 의존성 변경이므로 계획에 적고 승인을 받는다.
   - `scripts/download-rn-release.sh`의 기본값 `VERSION="${1:-v0.1.0}"`
   - CI workflow `1. poppang-build.yml`, `2. poppang-test.yml`, `3. poppang-build-and-test.yml`의 `./scripts/download-rn-release.sh v0.1.0`
   - 이 문서의 버전

RN 화면 자체의 수정은 RN 저장소에서 한다. 앱 저장소에 RN 소스를 복사하거나 받은 번들을 직접 고치지 않는다.

## 문제 해결

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| `tuist install`·`tuist generate`가 `PrebuiltReactNativeFrameworks`를 찾지 못한다. | SPM 산출물을 받지 않았다. | `./scripts/download-rn-release.sh v0.1.0`을 실행한다. |
| 앱에서 RN 화면을 열 때 `main.jsbundle을 찾을 수 없습니다.`로 멈춘다. | 번들을 받지 않았거나 받은 뒤 다시 빌드하지 않았다. | 스크립트를 실행하고 다시 빌드한다. |
| `gh release download`가 인증 오류로 실패한다. | GitHub CLI 로그인이 안 되어 있다. | `gh auth login` 후 다시 실행한다. |
| SPM 패키지를 받다가 `connection reset by peer`로 끝난다. | 150MB를 받는 중 네트워크 연결이 끊겼다. 스크립트는 실패하고 임시 폴더를 지운다. | 스크립트를 다시 실행한다. `| tail`처럼 파이프로 실행하면 실패가 가려지므로 종료 코드를 확인한다. |
| `main.jsbundle을 찾을 수 없습니다.` 또는 `Package.swift를 찾을 수 없습니다.`로 스크립트가 끝난다. | 릴리즈 zip 구조가 스크립트가 기대하는 구조와 다르다. | 해당 버전 릴리즈의 zip 내용을 RN 저장소에서 확인한다. |

## 에이전트 작업 규칙

- `scripts/download-rn-release.sh`는 파일을 지우고 새로 쓰므로 사용자 승인 없이 실행하지 않는다.
- 받은 산출물(`Projects/App/Resources/ReactNative/`, `Vendor/PrebuiltReactNativeFrameworks/`)을 커밋하지 않는다.

## 관련 문서

- [Tuist 설치와 실행](tuist.md)
- [TCA Navigation](../architecture/tca-navigation.md)
- [모듈 구조](../architecture/modules.md)
