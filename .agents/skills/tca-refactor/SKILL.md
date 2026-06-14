---
name: tca-refactor
description: PopPang iOS 앱 프로젝트 전용 Compound -> TCA 점진 전환 워크플로우. PopPang의 기존 refactor issue를 시작하거나 이어서 작업하면서 feature, coordinator boundary, dependency bridge를 Compound 기반 상태관리에서 Composable Architecture로 옮길 때 사용한다. root `Projects/*`를 실제 작업 대상으로 삼고, `V1/*`는 비교용으로만 참고한다. issue가 없으면 `global-auto-issue`를 사용하고, issue가 있으면 assign 승인, 자동 생성 브랜치 fetch/checkout, feature 단위 migration, reference 갱신, `auto-commit-push`와 `auto-pr` 연계를 포함한 PopPang 전용 흐름을 따른다.
---

# TCA Refactor

## 목적

PopPang의 Compound 기반 feature를 현재 루트 `Projects/*` 구조 안에서 안전하게 TCA로 점진 전환한다.

## 먼저 읽을 파일

이 스킬을 사용할 때는 아래 파일을 순서대로 읽는다.

1. `references/current-architecture.md`
2. `references/feature-migration-inventory.md`
3. `references/issue-branch-workflow.md`

요청이 특정 feature 하나에만 집중되어 있어도, 첫 사용 시점에는 세 문서를 모두 읽어 현재 기준선을 맞춘다.

## 작업 원칙

1. 루트 `Projects/*`를 실제 구현 대상으로 사용한다.
2. `V1/*`는 이전 상태 비교나 Compound 원형 확인이 필요할 때만 참고한다.
3. `AGENTS.md`의 plan-first 규칙을 계속 따른다.
4. feature 내부 상태는 reducer로 옮기되, 전역 navigation ownership은 기존 coordinator 구조를 우선 유지한다.
5. `PopupUsecaseProtocol`, `AdminUsecaseProtocol`, `UserUsecaseProtocol` 같은 public contract는 issue 범위가 명확히 허용하지 않는 한 초반에 분리하지 않는다.
6. 실제 migration으로 구조 이해가 바뀌면 reference 문서를 같은 작업 범위 안에서 갱신한다.

## Issue 시작 흐름

1. 기존 open issue가 있으면 새 issue보다 기존 issue를 우선 사용한다.
2. 관련 issue가 없으면 `global-auto-issue`를 사용해 issue를 먼저 만든다.
3. issue 구현을 시작하기 전에는 반드시 아래 문장으로 사용자 승인을 받는다.

```text
새로운 브랜치를 열기 위해 해당 이슈에 assign을 할당해도 되겠습니까?
```

4. 사용자가 명시적으로 수락하기 전에는 issue assign, branch 생성 트리거, 원격 write를 실행하지 않는다.
5. 사용자가 수락하면 현재 인증된 GitHub 사용자에게 issue를 assign한다.
6. assign 이후 자동 브랜치 생성 comment 또는 원격 브랜치 존재를 확인한 뒤에만 fetch/checkout을 진행한다.

issue 생성/assign/branch checkout의 자세한 절차는 `references/issue-branch-workflow.md`를 따른다.

## Migration 실행 흐름

1. issue 범위와 관련 reference를 다시 매핑한다.
2. target feature의 기존 Compound state/action/reaction 흐름을 읽는다.
3. 현재 저장소에서 이미 TCA로 옮겨진 예시를 먼저 비교한다.
4. reducer state, action, effect, dependency bridge의 초안을 잡는다.
5. coordinator callback을 유지할지, route를 올릴지, 화면 로컬 상태를 남길지 구분한다.
6. 구현 중 범위가 `Domain`, `Data`, `App`, `Coordinator`의 public contract로 번지면 작업을 멈추고 다시 승인을 받는다.
7. 구현 후에는 테스트/빌드/수동 검증 결과를 남긴다.
8. migration 결과에 따라 reference 문서를 갱신한다.

## TCA 패턴 기준

1. feature-scoped client를 만들어 `DIContainer.shared.resolve(...)`를 `DependencyValues` bridge 뒤로 숨긴다.
2. reducer에는 비즈니스 상태, effect 타이밍에 직접 영향을 주는 상태, 테스트가 필요한 상태를 둔다.
3. scroll offset, proxy, 일회성 animation 같은 순수 UI 임시 상태는 무조건 reducer로 올리지 않는다.
4. feature 간 이동은 coordinator callback 또는 route로 올리고, feature가 다른 feature를 직접 조립하지 않도록 유지한다.
5. Root/MainTab/FeatureCoordinator 구조는 issue가 명시적으로 요구하지 않는 한 먼저 TCA로 바꾸지 않는다.

구체적인 구조 기준과 현재 전환 상태는 `references/current-architecture.md`, `references/feature-migration-inventory.md`를 따른다.

## 완료 흐름

1. 구현이 끝나면 변경 요약과 검증 결과를 정리한다.
2. 사용자가 커밋/푸시까지 원하면 `auto-commit-push`를 사용한다.
3. 사용자가 PR 생성까지 원하면 `auto-pr`를 사용한다.
4. 사용자가 `auto-commit-pr`라고 표현해도 실제 프로젝트 스킬 이름은 `auto-pr`로 해석한다.
5. PR 생성 여부와 최종 merge 판단은 사용자에게 남긴다.

## Reference 갱신 규칙

아래 상황이면 reference를 업데이트한다.

- 어떤 feature가 Compound에서 TCA로 넘어갔을 때
- migration 우선순위나 issue mapping이 바뀌었을 때
- coordinator ownership, dependency bridge, module 경계에 대한 이해가 바뀌었을 때
- issue assign -> branch 생성 흐름이 실제 저장소 규칙과 달라졌을 때

reference를 바꿨다면 최종 응답에서 무엇을 갱신했는지 함께 설명한다.
