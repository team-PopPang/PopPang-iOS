# PopPang 커밋·PR의 AI 작성 표기 규칙

커밋 메시지와 PR 본문에 AI 도구의 공동 작성자 트레일러, 생성 문구, 세션 링크를 넣지 않는다. Codex, Claude Code를 포함한 모든 AI 에이전트가 커밋하거나 PR을 작성할 때 적용한다.

이 저장소의 기존 커밋에는 AI 공동 작성자 트레일러가 없다. 이 규칙은 그 관례를 문서로 고정한다.

## 넣지 않는 표기

| 위치 | 제외할 표기 예시 |
| --- | --- |
| 커밋 메시지 끝 | `Co-Authored-By: Claude ... <noreply@anthropic.com>` 같은 AI 공동 작성자 트레일러 |
| 커밋 메시지·PR 본문 | `Generated with Claude Code` 같은 생성 문구, 배지, 홍보 링크 |
| 커밋 메시지·PR 본문 | `Claude-Session`처럼 AI 작업 세션을 가리키는 자동 출처 표기 |

실제 사람의 공동 작성 기록, Git author·committer 정보, 저장소가 요구하는 `Signed-off-by`는 지우거나 바꾸지 않는다.

## Claude Code 설정

Claude Code는 설정으로 자동 표기를 끌 수 있다. 아래 값을 기존 설정 파일에 병합한다.

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

| 설정 | 결과 |
| --- | --- |
| `attribution.commit: ""` | 커밋에 자동으로 붙는 작성 표기를 없앤다. |
| `attribution.pr: ""` | PR 본문에 자동으로 붙는 작성 표기를 없앤다. |
| `attribution.sessionUrl: false` | 커밋의 세션 링크를 뺀다. |

`commit`이나 `pr` 중 하나만 지정하면 나머지에는 기본 문구가 붙을 수 있으므로 둘 다 지정한다.

| 적용 범위 | 설정 파일 |
| --- | --- |
| 이 저장소의 팀 공통 설정 | `.claude/settings.json` (커밋 대상) |
| 이 컴퓨터의 모든 프로젝트 | `~/.claude/settings.json` |
| 이 저장소에서 나만 | `.claude/settings.local.json` |

설정 파일이 이미 있으면 `permissions`, `hooks`, `env` 같은 기존 항목을 유지하고 `attribution`만 추가한다. 파일 전체를 덮어쓰지 않는다. 현재 저장소에는 `.claude/settings.json`이 없다. 팀 공통으로 둘지는 팀이 정한다.

설정은 자동 표기만 막는다. 에이전트가 직접 쓰는 메시지에도 이 문서의 규칙을 적용하고, 게시 전에 실제 내용을 확인한다.

## 게시 전 확인

```bash
# 마지막 커밋의 전체 메시지
git log -1 --format=%B

# 작업 브랜치에서 추가한 커밋의 전체 메시지
git log origin/main..HEAD --format='%h %s%n%b'

# 게시한 PR 본문
gh pr view <PR번호> --json body --jq .body
```

- AI 공동 작성자 트레일러가 없다.
- 본문 끝에 생성 문구, 배지, 세션 링크가 없다.
- 변경 내용, 검증 결과, 사람의 기여 기록은 남아 있다.

## 이미 게시한 표기를 정리할 때

설정을 바꿔도 기존 커밋과 PR 본문은 바뀌지 않는다. 정리는 사용자가 요청한 범위에서만 한다.

- PR 본문은 `gh pr edit <PR번호> --body-file <수정한본문파일>`로 고친다. 기존 설명과 체크리스트는 유지한다.
- 커밋 메시지를 고치면 해시가 바뀐다. push하지 않은 마지막 커밋만 amend를 검토한다. 이미 push한 커밋이나 공유 브랜치의 이력은 사용자 확인 없이 다시 쓰지 않는다.

## 관련 문서

- [Git 작업 흐름](gitflow.md)
- [AI 작업 흐름](ai-workflow.md)
- [Claude Code attribution 설정](https://code.claude.com/docs/en/settings-reference#attribution)
