---
name: auto-commit-push
description: PopPang iOS 앱 프로젝트 전용 git 커밋 및 푸시 워크플로우. 사용자가 "커밋해", "커밋하고 푸시해", "자동 커밋", "push까지 해줘"처럼 현재 저장소 변경사항을 커밋하거나 원격에 푸시하라고 요청할 때 사용한다. 커밋 메시지는 feat, chore, docs, fix, refactor, ci 중 하나와 한글 설명을 사용한다.
---

# Auto Commit Push

## 목적

PopPang 저장소에서 변경사항을 점검하고 프로젝트 규칙에 맞는 한글 커밋 메시지로 커밋한다. 사용자가 명시적으로 push까지 요청한 경우에만 현재 브랜치를 원격에 push한다.

## 커밋 메시지 규칙

사용 가능한 타입은 아래 6개뿐이다.

```text
feat: 한글 설명
chore: 한글 설명
docs: 한글 설명
fix: 한글 설명
refactor: 한글 설명
ci: 한글 설명
```

타입 선택 기준:

- `feat`: 새 기능, 새 화면, 사용자에게 보이는 기능 추가
- `fix`: 버그 수정, 깨진 동작 복구, 배포 후 문제 해결
- `refactor`: 동작 변경 없이 코드 구조 개선
- `docs`: 문서, AGENTS.md, README 성격의 변경만 있는 경우
- `chore`: 정리 작업, 로컬 설정, 스크립트 이름 변경, 기타 운영성 변경
- `ci`: 배포/자동화/파이프라인/검증 스크립트 변경이 핵심인 경우

설명은 한글로 짧게 쓴다. 예: `docs: Codex 작업 규칙 정리`

## 워크플로우

1. `git status --short`로 전체 변경사항을 확인한다.
2. `git diff --stat`과 필요한 파일별 diff를 읽어 변경 의도를 파악한다.
3. 커밋 대상에 금지 파일이 섞였는지 확인한다.
4. 변경사항이 서로 무관하게 섞여 있으면 하나의 커밋으로 묶지 말고 사용자에게 분리 기준을 확인한다.
5. 변경 성격에 맞춰 타입을 고르고 한글 커밋 메시지를 만든다.
6. 관련 파일만 `git add`로 stage한다. `git add .`는 사용하지 않는다.
7. `git diff --cached --stat`으로 stage 결과를 다시 확인한다.
8. `git commit -m "type: 한글 설명"`을 실행한다.
9. 사용자가 push를 명시한 경우에만 현재 브랜치를 확인한 뒤 `git push`를 실행한다.
10. 최종 응답에 커밋 해시, 메시지, push 여부를 짧게 보고한다.

## 커밋 금지 대상

아래 파일은 사용자가 별도로 승인하지 않는 한 stage하지 않는다.

- `.env`, `*.env`
- `*.xcconfig`
- `GoogleService-Info.plist`
- `.codex/logs/*.jsonl`
- `.DS_Store`
- `.spm/`, `.build/`, `.swiftpm/`, `.tuist/`, `Tuist/.build/`
- `DerivedData/`, `**/DerivedData/`, `**/Derived/`
- `*.xcodeproj/`, `*.xcworkspace/`
- `*.ipa`, `*.dSYM`, `*.dSYM.zip`, `graph.png`
- `fastlane/metadata/`, `fastlane/Preview.html`, `fastlane/report.xml`
- 인증키, 서버 접속 정보, 서비스 계정 JSON, 토큰, 비밀번호가 포함된 파일

금지 대상이 변경사항에 보이면 커밋하지 말고 사용자에게 알려야 한다.

## Push 규칙

- 사용자가 "push", "푸시", "올려"처럼 명시한 경우에만 push한다.
- push 전 `git branch --show-current`로 현재 브랜치를 확인한다.
- 원격 브랜치가 없어서 push가 실패하면 `git push -u origin <branch>` 실행 가능 여부를 사용자에게 확인한다.
- push 실패 시 재시도하지 말고 에러 요지를 보고한다.
