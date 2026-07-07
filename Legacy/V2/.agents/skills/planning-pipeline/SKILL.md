---
name: planning-pipeline
description: PopPang iOS 앱 프로젝트 전용 계획/방향성 검토 워크플로우. 사용자가 "계획세워줘", "방향성 잡아줘", "구현 전에 검토해줘", "수정 방향 먼저 정리해줘", "리팩터링 방향 제안해줘"처럼 구현 전 계획이나 접근 방법을 요청할 때 사용한다.
---

# Planning Pipeline

## 목적

PopPang 저장소에서 구현 전에 Researcher, Planner, Reviewer 관점을 순서대로 적용해 작업 방향을 정리한다. 이 스킬은 파일을 수정하지 않고 계획과 리스크만 제시한다.

## 사용할 프롬프트

이 스킬을 사용할 때는 저장소 루트 기준으로 아래 파일을 순서대로 읽고 적용한다.

1. `Docs/poppang-architecture.md`
2. `.codex/prompts/researcher.md`
3. `.codex/prompts/planner.md`
4. `.codex/prompts/reviewer.md`

문서나 프롬프트 파일이 없거나 읽을 수 없으면 파일을 생성하지 말고, 누락된 경로를 사용자에게 알린 뒤 현재 확인 가능한 정보로만 계획을 작성한다.

## 적용 조건

아래와 같은 요청에 사용한다.

- "계획세워줘"
- "기능 방향성을 제시해줘"
- "구현 방향을 먼저 잡아줘"
- "버그를 고치기 전에 접근 방법을 정리해줘"
- "리팩터링 방향을 제안해줘"
- "구현하지 말고 계획만 세워줘"

사용자가 "바로 구현해", "진행해", "수정해"처럼 이미 구현 승인을 명시한 경우에는 이 스킬로 계획만 반복하지 않는다. 다만 `AGENTS.md`의 plan-first 승인 규칙은 계속 따른다.

## 워크플로우

1. `AGENTS.md`의 plan-first 규칙을 먼저 적용한다.
2. `Docs/poppang-architecture.md`를 읽고 PopPang의 기본 모듈 구조, 의존성 방향, DI, navigation, 문서 동기화 규칙을 기준 맥락으로 삼는다.
3. `.codex/prompts/researcher.md`를 읽고 Researcher 관점으로 요청 관련 실제 코드와 제약을 정리한다.
4. `.codex/prompts/planner.md`를 읽고 Planner 관점으로 접근 방법, 추천 방향, 변경 범위, 테스트 계획, 문서 업데이트 필요 여부를 정리한다.
5. `.codex/prompts/reviewer.md`를 읽고 Reviewer 관점으로 리스크, 테스트 누락, 범위 이탈 위험, 문서 누락 위험을 검토한다.
6. 최종 추천 방향과 다음 단계를 요약한다.
7. 파일 생성, 수정, 삭제 없이 응답을 마친다.

## 출력 형식

아래 형식을 사용한다.

```text
## Researcher 관점

## Planner 관점

## Reviewer 관점

## 최종 추천 방향
```

필요한 경우 마지막에 아래 문장을 포함한다.

```text
위 계획으로 진행해도 될까요? 승인 전까지 파일은 수정하지 않겠습니다.
```

## 금지 사항

- 사용자 승인 없이 파일을 생성, 수정, 삭제하지 않는다.
- `.env`, `GoogleService-Info.plist`, `*.xcconfig`, 인증키, 토큰, 비밀번호를 열람하거나 출력하지 않는다.
- API 계약, DTO, public protocol, DI 구조, 모듈 의존성, Tuist 설정 변경을 가볍게 제안하지 않는다.
- `tuist generate`, `make regen`처럼 파일을 생성하거나 갱신할 수 있는 명령을 승인 없이 실행하지 않는다.
- 구현 단계의 세부 코드 변경을 확정 사실처럼 말하지 않는다.
- 코드 변경으로 `Docs/poppang-architecture.md`, `Projects/Coordinator/README.md`, `Docs/static-dynamic-linking.md`, `Docs/Troubleshotting.md` 같은 기준 문서가 달라져야 하는데도 문서 영향 여부를 생략하지 않는다.
