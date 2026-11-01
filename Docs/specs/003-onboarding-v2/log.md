# 온보딩 화면 V2 디자인 진행 기록

- 스펙: [spec.md](spec.md) · 체크리스트: [tasks.md](tasks.md)

<!-- 덧붙이기만 한다. 이전 기록은 고치지 않는다. -->

## 2026-11-01 시작

- 스펙 폴더를 만들었다.
- 피그마 분석과 1차 답을 반영해 설계를 썼다. 상태: 설계 승인 대기.
- 승인: 설계 (2026-11-01) — "설계 승인". D-2, D-5 이름 확인. 상태: 스펙 승인 대기.
- 테크 스펙: 에셋 이름, 새 문구 ko·en·ja 표, 가정 A-4·A-5를 채웠다.
- 2차 답: 3번 설명 문구를 1번안으로 바꿨다.
- 승인: 스펙 (2026-11-01) — "1번으로 하고 스펙 승인". 상태: 체크리스트 승인 대기.
- 체크리스트 S01~S03을 썼다.
- 승인: 체크리스트 (2026-11-01) — "체크리스트 승인". 상태: 구현 중.

## 2026-11-01 S01

- 시작: 이슈 #136, 브랜치 `feature/#136` (6f27f8d). 이슈 브랜치는 담당자를 지정해야 만들어진다(`issues: assigned`).
- `OnboardingFeatureV2` 모듈(본체·Demo·Tests)을 만들고 기존 Reducer·View·문구를 그대로 복사했다. 앱 `Project.swift`, `8. AppFeature.swift`, `7. AppRootFlowView.swift`가 V2를 import한다. `7. AppRootFlowView.swift`는 계획의 바꿀 파일에 없었는데 온보딩을 import하고 있어 함께 바꿨다.
- `xcodebuild test -scheme OnboardingFeatureV2 -only-testing:OnboardingFeatureV2Tests` → 4개 통과.
- `rg -n "import OnboardingFeature$" Projects/App` → 결과 없음.
- `xcodebuild build -scheme PopPangApp` → BUILD SUCCEEDED.
- 남은 조건: 새로 설치한 앱에서 온보딩 → 시작하기 → 로그인 화면 직접 확인 (사용자).
- 사용자 확인: 시뮬레이터에서 온보딩 흐름과 로그인 화면 이동 확인 ("S01 완료로 표시하고 S02 진행해줘"). S01 [x].

## 2026-11-01 S02

- 시작: `feature/#136`, 커밋 전 작업 트리 (S01 변경 포함).
- 아이콘 SVG 4개(종, 지도 핀, 달력, 화살표)를 `DSKit/Resources/Assets.xcassets/OnboardingV2/`에 넣었다. 지도 핀은 피그마가 30×30 틀 안 (4, 1.5)에 그룹을 두어서, 같은 위치로 감싼 30×30 SVG로 만들었다.
- 색 4개를 `UIConstants.swift`에, 새 화면·`OnboardingNextButton`·새 문구 ko·en·ja를 V2 모듈에 넣었다. 옛 문구 6개는 V2 카탈로그에서 지웠다.
- 막힘: 피그마 연결의 화면 캡처는 노드 원래 크기(353×383, 1배)까지만 나와 카드 PNG @2x·@3x를 받지 못했다. 사용자에게 피그마 내보내기를 요청했다.
- `xcodebuild test -only-testing:OnboardingFeatureV2Tests` → 6개 중 카드 에셋 테스트 1개(3건) 실패, 나머지 통과. 카드 PNG가 아직 없어서다.
- 진행 (2026-11-01): 피그마 연결 `download_assets`(PNG 3배)로 카드 3장을 받아 `OnboardingV2Card1~3.imageset`에 넣었다. 카드 1은 2배도 받았고, 카드 2·3의 2배는 호출 한도에 걸려 3배를 `sips`로 줄여 만들었다. 사용자가 "se에서는 화면이잘려"라고 알려, 카드가 먼저 줄어들게(`layoutPriority(-1)`) 하고 홈 바가 없는 기기는 버튼 아래 여백 16을 줬다. 테스트 6개 통과, `rg -n "figma.com/api/mcp/asset" Projects` 결과 없음, PopPangApp BUILD SUCCEEDED. 사용자 화면 확인 대기.
- 완료: S02 (2026-11-01) — 사용자가 "S02 완료로 표시하고 S03 진행해줘"로 화면 확인을 마쳤다. 완료 조건 실행 결과는 바로 위 기록과 같다(테스트 6개 통과, rg 결과 없음, BUILD SUCCEEDED).
- 진행 (2026-11-01): S03 시작. 작은 화면 대응은 S02 확인 중에 먼저 넣었다(카드 `layoutPriority(-1)`, 홈 바 없는 기기 버튼 아래 여백 16). `Docs/architecture/architecture.md`(모듈 지도·모듈 표·의존성 그림)와 `Docs/development/testing.md`(실행 명령·테스트 표)에 `OnboardingFeatureV2`를 더했다. 실행: `rg -n "OnboardingFeatureV2" Docs/architecture Docs/development/testing.md` → 5줄, `OnboardingFeatureV2Tests` 6개 통과, `xcodebuild test -scheme Data` 77개 통과, PopPangApp BUILD SUCCEEDED. 남은 것: 사용자가 iPhone SE에서 3장 모두 잘리지 않는지 확인.
- 완료: S03 (2026-11-01) — 사용자가 "S03 완료로 표시해줘"로 iPhone SE 확인을 마쳤다. 완료 조건 실행 결과는 바로 위 기록과 같다. 모든 단계가 끝나 스펙 상태를 완료로 바꿨다.
