# PopPang Tuist 설치와 실행

기준일: 2026-10-01

이 문서는 새 Mac에서 Tuist를 설치하고 PopPang workspace를 만드는 순서를 정리한다. 모듈 구조와 product type 기준은 [모듈 구조](../architecture/modules.md)를 본다.

## 기준 버전

Tuist 버전은 `4.210.0`으로 고정한다. 같은 값이 두 파일에 있다.

| 파일 | 값 | 읽는 곳 |
| --- | --- | --- |
| `mise.toml` | `4.210.0` | 로컬. `tuist`를 실행하면 mise가 이 파일을 보고 버전을 고른다. Makefile, fastlane, scripts도 모두 `tuist`를 그대로 부른다. |
| `.tuist-version` | `4.210.0` | CI. `.github/workflows/0~3`이 `mise install tuist@$(cat .tuist-version)`으로 설치한다. |

두 파일의 값은 항상 같아야 한다. 버전을 바꿀 때는 `mise.toml`, `.tuist-version`, README를 함께 고치고, 빌드 영향이 있으므로 계획에 적고 승인을 받는다.

4.210.0은 Xcode 27(Swift 6.4)에서 패키지 타깃의 최소 버전을 iOS 15.0 이상으로 올려 생성하고, SwiftPM trait(swift-dependencies의 `Clocks` 등)를 컴파일 조건과 의존성으로 옮긴다. 4.115.0은 둘 다 하지 않아 Xcode 27에서 패키지 최소 버전 오류와 `continuousClock` 누락 오류가 난다. 버전을 바꾼 뒤 오류가 나면 [문제 해결](#문제-해결)을 본다.

```toml
# mise.toml
[tools]
tuist = "4.210.0"
```

## 설치 순서

[mise](https://mise.jdx.dev)로 설치한다. mise는 프로젝트 폴더의 `mise.toml`을 읽고 적힌 버전의 Tuist를 설치·실행한다.

### 1. mise 설치

```bash
brew install mise
```

### 2. zsh에 mise 등록

```bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

이 줄은 셸 프롬프트가 뜰 때마다 현재 폴더의 `mise.toml`에 맞춰 `PATH`를 바꾼다. 등록한 뒤 새 터미널 탭을 열거나 아래 명령으로 설정을 다시 불러온다.

```bash
source ~/.zshrc
```

### 3. Tuist 설치

저장소 루트에서 실행한다. 다른 폴더에서 실행하면 `mise.toml`을 찾지 못한다.

```bash
mise install
```

성공하면 아래처럼 출력된다.

```text
mise ✓ tuist@4.210.0  13.7s  tuist.zip
mise ████████████████ 1/1 · installed 1 tool in 14.2s
```

다른 버전(예: 이전에 쓰던 4.115.0)이 이미 설치되어 있어도 이 폴더에서는 `mise.toml`의 버전만 쓴다.

### 4. 버전 확인

```bash
tuist version
```

`4.210.0`이 나오면 설치가 끝난 것이다.

## workspace 만들기

### 1. 비밀 설정 파일 배치

`Projects/App/Secrets.xcconfig`와 `GoogleService-Info.plist`는 저장소에 없다(`.gitignore`). 팀에서 받아 배치한다. 예전 `make download-privates` 타깃은 주석 처리되어 있다. 이 파일들의 내용을 문서나 로그에 옮기지 않는다.

### 2. React Native 산출물 받기

`App`과 `PopPangRNFeature`는 `Vendor/PrebuiltReactNativeFrameworks` local package를 참조한다. 이 폴더가 없으면 `tuist install`과 `tuist generate`가 실패하므로 먼저 받는다. `gh auth login`이 되어 있고 `team-PopPang/PopPang-RN` 저장소에 접근할 수 있어야 한다.

```bash
./scripts/download-rn-release.sh v1.0.0
```

스크립트는 `Projects/App/Resources/ReactNative`(번들)와 `Vendor/PrebuiltReactNativeFrameworks`(SPM 패키지)를 채운다. 두 경로 모두 `.gitignore`에 들어 있다. 산출물 내용과 버전 변경 방법은 [React Native 산출물](react-native.md)을 본다.

### 3. 패키지 설치와 workspace 생성

```bash
tuist install
tuist generate
```

`tuist generate`는 `*.xcodeproj`, `PopPang.xcworkspace`, `Derived/`를 만든다. 이 파일들은 `.gitignore`에 들어 있는 생성물이므로 직접 고치거나 커밋하지 않는다.

생성물을 지우고 다시 만들 때는 아래 명령을 쓴다.

```bash
make regen
```

## 자주 쓰는 명령

| 목적 | 명령 |
| --- | --- |
| 앱 빌드 | `tuist build PopPangApp` |
| 모듈 빌드 | `tuist build MainTabFeature` |
| 모듈 테스트 | `tuist test Core`, `tuist test Data` |

Makefile 타깃은 아래와 같다. `make`만 실행하면 `default: all`의 `all`이 정의되어 있지 않아 실패하므로 타깃을 지정한다.

| 타깃 | 하는 일 |
| --- | --- |
| `make module-help` | 모듈 생성 사용법과 layer 목록을 출력한다. |
| `make module LAYER=<layer> NAME=<Name>` | `tuist scaffold`로 모듈을 만든다. feature는 `INTERFACE=true`를 줄 수 있다. 주의할 점은 [모듈 구조](../architecture/modules.md#새-모듈-만들기)를 본다. |
| `make regen` | `Projects/**/*.xcodeproj`와 `Derived`를 지우고 `tuist generate`를 실행한다. |
| `make trash` | 빌드 폴더, `Derived`, PopPang DerivedData를 지운다. |
| `make clean` | `trash`에 더해 `PopPang.xcworkspace`, 모든 `*.xcodeproj`를 지우고 `tuist clean`을 실행한다. |
| `make reinstall` | `clean` → `tuist install` → `tuist generate` |

fastlane에는 `build`(PopPangApp 시뮬레이터 빌드), `test`(Core·Data 테스트), `ci`(`build` + `test`), `beta`, `release` lane이 있다. `beta`와 `release`가 올린 버전은 생성된 `App.xcodeproj`에만 반영되고 `Projects/App/Project.swift`의 `MARKETING_VERSION`에는 남지 않는다(`확인 필요`).

테스트 타깃과 실행 기준은 [테스트](testing.md)를, 모듈 생성 규칙은 [모듈 구조](../architecture/modules.md)를 본다.

## 문제 해결

### `zsh: command not found: tuist`

| 원인 | 확인 | 해결 |
| --- | --- | --- |
| Tuist를 아직 설치하지 않았거나 다운로드 중이다. | `mise ls`에 `tuist 4.210.0 (missing)`이 보인다. | 저장소 루트에서 `mise install`을 실행하고 끝날 때까지 기다린다. |
| 셸에 mise가 등록되지 않았다. | `grep mise ~/.zshrc` 결과가 비어 있다. | [2단계](#2-zsh에-mise-등록)를 실행한다. |
| 등록했지만 현재 탭에 아직 적용되지 않았다. | 새 탭에서는 동작한다. | `source ~/.zshrc`를 실행하거나 새 탭을 연다. |
| 저장소 밖 폴더에 있다. | `pwd`가 저장소 루트가 아니다. | 저장소 루트로 이동한다. |

### Tuist 버전을 바꾼 뒤 `module map file ... not found`

`Tuist/.build`는 Tuist 버전마다 구조가 다르다. 4.210.0은 패키지 project를 `Tuist/.build/tuist-derived/Projects/<패키지>/`에 만들고, `Tuist/.build/checkouts/<패키지>`를 `~/.cache/swifterpm/sources/` 아래 공용 캐시를 가리키는 심볼릭 링크로 만든다. 다른 버전이 만든 `Tuist/.build`가 섞여 있으면 모듈맵 상대 경로가 깨져 `module map file '.../checkouts/<패키지>/../../tuist-derived/...' not found` 같은 오류가 난다.

`Tuist/.build`를 지우고 현재 버전으로 다시 받는다.

```bash
rm -rf Tuist/.build
tuist install
tuist generate
```

### AI 에이전트 창에서 실행할 때

Claude Code나 Codex에서 `!`로 실행하는 셸은 프롬프트를 띄우지 않을 수 있어 `mise activate`가 적용되지 않는다. 이때는 `mise exec`로 실행한다.

```bash
mise exec -- tuist version
```

### Homebrew의 Command Line Tools 경고

`brew install mise` 중에 `Your Command Line Tools are too outdated.`가 나와도 mise 설치는 끝날 수 있다. 다른 brew 패키지를 위해 System Settings → Software Update에서 Command Line Tools를 업데이트한다. 업데이트가 보이지 않으면 아래 명령을 차례로 실행한다.

```bash
sudo rm -rf /Library/Developer/CommandLineTools
sudo xcode-select --install
```

## 에이전트 작업 규칙

- `tuist generate`, `tuist install`, `make regen`, `make trash`, `make clean`, `make reinstall`, `make module`, `scripts/download-rn-release.sh`는 파일을 만들거나 지우므로 사용자 승인 없이 실행하지 않는다.
- Tuist 버전을 바꾸는 작업은 빌드 영향이 있으므로 계획에 적고 승인을 받는다.
- 링크 오류가 나면 [모듈 구조](../architecture/modules.md)의 product type과 ThirdParty 기준부터 확인한다.
