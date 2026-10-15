# PopPang PR 작성 예시

PR에는 리뷰어가 변경 이유와 결과를 판단할 정보를 적어요. 본문은 `.github/PULL_REQUEST_TEMPLATE.md`의 섹션과 순서를 유지하고 해요체로 써요. 변경 사항 bullet은 `- ...했어요.`로 써요. 제목은 연결된 이슈 제목과 같게 써요.

예시의 성공 문구를 그대로 복사하지 않아요. 실제 PR에서는 현재 diff와 실행 결과로 바꿔요.

## 작은 문서 수정은 변경과 확인만 써요

상황: README의 Tuist 설치 문서 링크가 잘못되어 경로를 고쳤고, 링크 대상 파일이 있는지 확인했어요. (가상 사례)

제목: `[docs] README의 Tuist 설치 문서 링크를 수정한다`

같은 사실을 여러 섹션에서 반복한 본문:

```markdown
## ✏️ 변경 사항

- README의 Tuist 설치 문서 링크를 수정했어요.
- 링크 경로를 변경했어요.

## 🔥 추가 설명

- README의 링크가 잘못되어 수정이 필요했어요.
- 결론적으로 README의 링크를 수정했어요.
```

정리한 본문:

```markdown
## ✏️ 변경 사항

- README의 Tuist 설치 문서 링크를 `Docs/development/tuist.md`로 수정했어요.

## 🔥 추가 설명

- 링크 대상 파일이 있는지 확인했어요. 문서만 바꿔서 앱 빌드와 테스트는 실행하지 않았어요.
```

변경 이유·결과·확인 내용이 모두 있어요. 파일 하나를 고친 작업에 영향 분석이나 결론을 붙이지 않아요. 앱 테스트를 실행하지 않았으니 통과했다고 쓰지 않아요. `💡 PR 유형`, `🚨 관련 이슈`, `🎨 스크린샷`, `✅ 체크리스트` 섹션은 템플릿대로 둬요.

## 버그 수정은 원인과 바뀐 동작을 설명해요

실제 PR #92를 줄이고 해요체로 옮긴 예시예요. 제목은 이슈 #91 제목과 같아요.

제목: `[fix] 프로필 닉네임 변경 후 홈 헤더가 갱신되지 않는 문제를 해결한다`

```markdown
## ✏️ 변경 사항

- `HomeFeatureV2`의 베스트 팝업 헤더 item을 고정 값에서 현재 닉네임으로 바꿨어요.
- `HomeFeatureV2`의 닉네임 갱신 reducer 회귀 테스트를 추가했어요.

### 문제 원인

`MainTabFeature`는 프로필 설정의 `.nicknameUpdated` delegate를 받아 홈 상태와 shared session을 정상적으로 갱신하고 있었어요. 그런데 `HomeFeatureV2`의 `PopPangListKit.Section.withHeader(item:)`은 고정 item을 써서, 재사용된 헤더가 새 닉네임으로 구성되지 않았어요.

### 해결 내용

닉네임을 header item으로 넘겨, 값이 달라질 때 해당 헤더만 업데이트하도록 고쳤어요.

### 검증한 내용

- `HomeFeatureV2Tests`를 실행했어요.
- `MainTabFeatureTests`를 실행해 프로필 변경 후 홈·프로필·공유 세션의 닉네임 동기화를 확인했어요.

## 🔥 추가 설명

- 검증 명령: `xcodebuild test -workspace PopPang.xcworkspace -scheme HomeFeatureV2 -destination 'id=<시뮬레이터 UDID>' -only-testing:HomeFeatureV2Tests`
- 실제 계정으로 닉네임을 바꾼 뒤 홈 헤더가 갱신되는지 보는 UI 확인과 스크린샷 첨부는 따로 필요해요.
```

`item 값 변경`, `테스트 파일 추가`처럼 diff에 보이는 항목만 나열하지 않고, 왜 갱신되지 않았는지와 무엇이 달라졌는지를 이어서 썼어요. 실행한 명령과 아직 확인하지 못한 UI 검증을 함께 적었어요.

## 영향 범위가 큰 변경은 필요한 설명을 남겨요

상황: `PopupUsecaseProtocol`에 메서드를 추가하고, `PopupRepositoryImpl`, `AppDependencyRegistry` 조립, feature client, Demo stub을 함께 고쳐요. Demo 일부는 빌드하지 못했어요. (가상 사례)

제목: `[feat] 팝업 상세에 관련 리뷰 목록 조회를 추가한다`

```markdown
## ✏️ 변경 사항

- `PopupUsecaseProtocol`과 `PopupRepositoryProtocol`에 관련 리뷰 조회 메서드를 추가했어요.
- `PopupDetailClient`에 조회 closure를 추가하고 `MainTabFeatureDependencies`에서 조립했어요.

### 영향 범위

`PopupUsecaseProtocol`은 public protocol이라서 이를 구현하거나 stub으로 만드는 곳을 모두 고쳤어요. 같은 저장소의 `PopupUsecaseImpl`과 Demo 앱의 inline stub이 해당해요.

### 검증한 내용

- `PopPangApp` 빌드와 `DataTests`를 실행했어요.
- `PopupDetailFeatureDemo`는 빌드했고, `CalendarFeatureDemo`는 빌드하지 못했어요. 해당 Demo의 client stub 확인이 필요해요.
```

이런 경우 한 문장으로 줄이면 public protocol 변경의 영향과 검증하지 못한 범위를 놓쳐요. 영향을 받는 위치와 남은 확인을 본문에 남겨요.

## 검증 결과가 없으면 그대로 밝혀요

`테스트 완료`, `문제없음`, `기존 동작 유지`는 근거 없이 쓰지 않아요. 문서 링크만 확인했다면 `링크 대상 파일이 있는지 확인했어요.`라고 써요. 필요한 테스트를 실행하지 못했다면 명령, 실패 이유, 남은 확인 범위를 적어요.

`✅ 체크리스트`의 "정상적으로 동작하는지 확인했나요?"는 빌드·테스트·수동 확인 가운데 실제로 한 것이 있을 때만 체크해요.

## 게시 전에 확인할 것

- 변경 사항 첫 bullet에서 무엇이 달라졌는지 알 수 있나요?
- 같은 사실을 제목·변경 사항·추가 설명에서 반복하지 않았나요?
- 조건·영향·검증 한계를 줄이는 과정에서 숨기지 않았나요?
- 실제 diff와 검증 결과에 없는 주장을 더하지 않았나요?
- 제목이 이슈 제목과 같나요?
- 본문의 어미가 해요체로 통일됐나요?

## 관련 문서

- [한국어 윤문 원칙](../korean-editing.md)
- [문서 윤문 예시](korean-editing-examples.md)
- [Git 작업 흐름](../gitflow.md)
- [AI 작성 표기 규칙](../ai-attribution.md)
