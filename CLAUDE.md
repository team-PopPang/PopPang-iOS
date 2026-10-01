# PopPang Claude Code 작업 안내

@AGENTS.md

> Claude Code는 위 줄로 `AGENTS.md`를 프로젝트 공통 규칙으로 불러온다. 공통 규칙은 이 파일에 반복해서 적지 않는다.

## Claude Code에만 해당하는 내용

- 프로젝트 스킬은 Codex 경로인 `.agents/skills/`에 있고, Claude Code는 이 경로를 자동으로 불러오지 않는다. 요청이 스킬에 해당하면 `.agents/skills/<name>/SKILL.md`를 직접 읽고 따른다.
- `.codex/hooks.json`의 작업 로그는 Claude Code 세션에서 기록되지 않는다.
- 커밋 메시지와 PR 본문에 `Co-Authored-By: Claude ...` 트레일러와 `Generated with Claude Code` 문구를 넣지 않는다. 자동 표기를 끄는 설정은 [AI 작성 표기 규칙](Docs/development/ai-attribution.md#claude-code-설정)을 본다.
- `!`로 실행하는 셸에는 `mise activate`가 적용되지 않을 수 있다. Tuist 명령은 `mise exec -- tuist <명령>`으로 실행한다.

## 이 파일을 고치는 기준

- 프로젝트 공통 규칙을 바꿀 때는 `AGENTS.md`나 `Docs/` 문서를 고친다.
- Claude Code에만 필요한 지침이 생길 때만 이 파일에 추가한다.
