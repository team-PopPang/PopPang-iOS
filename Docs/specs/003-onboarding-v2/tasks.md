# 온보딩 화면 V2 디자인 개발 순서와 체크리스트

- 스펙: [spec.md](spec.md) · 진행 기록: [log.md](log.md)

<!-- 단계 목록의 체크박스가 진행 상태의 기준이다. [x]만 완료로 센다. -->

## 단계 목록

- [x] S01 OnboardingFeatureV2 모듈을 만들고 앱을 V2로 바꾸기 (화면은 기존과 같음)
- [x] S02 새 디자인 화면 3장 (에셋, 색, 문구, 화살표 버튼)
- [x] S03 작은 화면 대응, 문서 갱신, 전체 검증

공통 명령의 `<sim>`은 `id=7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74`다. `xcodebuild` 전에는 `mise exec -- tuist generate --no-open`을 먼저 실행한다.

## S01 OnboardingFeatureV2 모듈을 만들고 앱을 V2로 바꾸기 (화면은 기존과 같음)
- 요구사항: R6
- 결정: D-1, D-2
- 할 일:
  - main에서 이슈를 만들고 자동으로 생긴 이슈 브랜치로 옮긴다.
  - `Projects/Features/OnboardingFeatureV2`를 만든다. 타깃: `OnboardingFeatureV2`(staticFramework), `OnboardingFeatureV2Demo`, `OnboardingFeatureV2Tests`. 의존성은 기존 모듈과 같다(Domain, DSKit, ThirdParty).
  - 기존 `OnboardingFeature.swift`, `OnboardingFeatureView.swift`, `Localizable.xcstrings`를 그대로 복사한다. 타입 이름은 바꾸지 않는다.
  - `Projects/App/Project.swift`와 `8. AppFeature.swift`(및 온보딩을 import하는 앱 파일)를 `OnboardingFeatureV2`로 바꾼다. 기존 모듈은 지우지 않는다.
  - `OnboardingFeatureV2Tests`: 다음 → 다음 단계, 마지막 다음 → `authRequested`, 건너뛰기 → `authRequested`, `stepChanged`.
- 바꿀 파일:
  - `Projects/Features/OnboardingFeatureV2/Project.swift` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Sources/Presentation/OnboardingFeature.swift` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Sources/Presentation/OnboardingFeatureView.swift` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Resources/Localizable.xcstrings` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Demo/Sources/OnboardingFeatureV2DemoApp.swift` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Tests/OnboardingFeatureV2Tests.swift` (새 파일)
  - `Projects/App/Project.swift`, `Projects/App/Sources/AppCore/Navigation/8. AppFeature.swift`
  - `Workspace.swift` (모듈 목록이 있으면)
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme OnboardingFeatureV2 -destination <sim> -only-testing:OnboardingFeatureV2Tests` → 기대: 4개 통과 (이 단계 전에는 scheme이 없어 실패)
  - `rg -n "import OnboardingFeature$" Projects/App` → 기대: 결과 없음
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: 시뮬레이터에서 앱을 지우고 새로 설치하면 기존과 같은 온보딩이 나오고, 시작하기를 누르면 로그인 화면이 나온다

## S02 새 디자인 화면 3장 (에셋, 색, 문구, 화살표 버튼)
- 요구사항: R1, R2, R3, R4, R5, R7
- 결정: D-3, D-4, D-5
- 할 일:
  - 피그마에서 카드 PNG 3장(@2x, @3x)과 아이콘·화살표 SVG 4개를 받아 DSKit `Assets.xcassets/OnboardingV2/`에 넣는다. 이름은 spec.md 데이터 모델 표를 따른다.
  - DSKit `UIConstants.swift`에 `onboardingGray`, `onboardingCard`, `onboardingBody`, `onboardingDot`을 추가한다.
  - `OnboardingFeatureView`를 새 배치로 바꾼다: 건너뛰기 줄 → 그림 카드 → 아이콘·제목·설명(왼쪽 정렬) → 점 → 버튼. 값은 spec.md 피그마 값 표를 따른다.
  - V2 모듈 안에 `OnboardingNextButton`을 만든다: 모서리 10, 높이 52, Medium 15, 화살표 24. 마지막 화면은 "시작하기"이고 화살표가 없다.
  - `OnboardingStep`의 아이콘·카드·문구를 새 것으로 바꾸고, 새 문구 ko·en·ja를 `Localizable.xcstrings`에 넣는다. 쓰지 않는 옛 문구는 V2 카탈로그에서 지운다.
  - 테스트: `OnboardingStep`의 카드·아이콘 이름이 DSKit 에셋에 있는지 확인하는 테스트를 더한다.
- 바꿀 파일:
  - `Projects/Shared/DSKit/Resources/Assets.xcassets/OnboardingV2/` (새 폴더)
  - `Projects/Shared/DSKit/Sources/Support/UIConstants.swift`
  - `Projects/Features/OnboardingFeatureV2/Sources/Presentation/OnboardingFeatureView.swift`
  - `Projects/Features/OnboardingFeatureV2/Sources/Presentation/OnboardingNextButton.swift` (새 파일)
  - `Projects/Features/OnboardingFeatureV2/Resources/Localizable.xcstrings`
  - `Projects/Features/OnboardingFeatureV2/Tests/OnboardingFeatureV2Tests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme OnboardingFeatureV2 -destination <sim> -only-testing:OnboardingFeatureV2Tests` → 기대: 에셋 확인 테스트를 포함해 통과 (이 단계 전에는 에셋이 없어 실패)
  - `rg -n "figma.com/api/mcp/asset" Projects` → 기대: 결과 없음 (임시 주소를 코드에 남기지 않음)
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: iPhone 17 시뮬레이터에서 3장이 피그마 화면과 같아 보이고, 영어·일본어(`-AppleLanguages`)에서 새 번역이 나온다

## S03 작은 화면 대응, 문서 갱신, 전체 검증
- 요구사항: R1, R6
- 할 일:
  - 화면 높이가 작으면 그림 카드 높이를 줄여 버튼이 잘리지 않게 한다 (A-1).
  - `Docs/architecture`의 모듈 목록·의존성 표에 `OnboardingFeatureV2`를 더하고, 앱이 V2를 쓴다고 적는다.
  - `Docs/development/testing.md`에 `OnboardingFeatureV2Tests` 줄을 더한다.
  - 전체 테스트와 빌드를 다시 돌리고, 직접 확인할 동작을 사용자에게 요청한다.
- 바꿀 파일:
  - `Projects/Features/OnboardingFeatureV2/Sources/Presentation/OnboardingFeatureView.swift`
  - `Docs/architecture/` 의 모듈 문서
  - `Docs/development/testing.md`
- 완료 조건:
  - `rg -n "OnboardingFeatureV2" Docs/architecture Docs/development/testing.md` → 기대: 결과 있음 (이 단계 전에는 없음)
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme OnboardingFeatureV2 -destination <sim> -only-testing:OnboardingFeatureV2Tests` → 기대: 통과
  - `mise exec -- tuist test Data` (또는 건너뛰면 `xcodebuild test -scheme Data`) → 기대: 통과
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: iPhone SE(3세대) 시뮬레이터에서 3장 모두 버튼과 글자가 잘리지 않는다
