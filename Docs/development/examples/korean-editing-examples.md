# PopPang 한국어 문서 윤문 예시

[한국어 윤문 원칙](../korean-editing.md)을 적용한 전후 비교다. 예시 문장의 동작은 `Projects/` 코드에서 확인한 내용이다.

## 문장만 다듬을 때: 주체와 행동을 밝힌다

`HomeFeature`(HomeFeatureV2)가 `popupSectionsLoaded`에서 state를 갱신하고 `loadingChanged(false)`로 로딩을 끝낸다는 사실을 코드에서 확인한 경우다. 의미와 순서를 유지하며 명사형 표현을 줄인다.

**수정 전**

> `HomeFeature`에서는 팝업 목록 응답 결과에 대한 화면 상태로의 반영 처리를 수행한 후 로딩 종료를 진행한다.

**수정 후**

> `HomeFeature`가 팝업 목록 응답을 화면 상태에 반영하고 로딩을 끝낸다.

주체, 입력, 결과를 남겼다. `반영 처리를 수행한다`와 `로딩 종료를 진행한다`를 동사로 바꿨다. 원문에 없는 응답 개수나 화면 이름은 추가하지 않는다.

## 간결하게 다듬을 때: 조건과 불확실성을 남긴다

**수정 전**

> 팝업 목록 요청이 실패한 경우에는 오류 메시지를 상태에 저장하는 처리를 수행한다. 다만 요청의 성공 여부와 상관없이 마지막에는 로딩을 종료하게 된다.

**수정 후**

> 팝업 목록 요청이 실패하면 오류 메시지를 상태에 저장한다. 성공하든 실패하든 마지막에 로딩을 끝낸다.

`실패하면 오류 메시지를 저장한다`만 남기면 성공했을 때도 로딩을 끝낸다는 동작이 사라진다(`HomeFeature.loadAllPopupData`). 문장을 줄여도 두 경로를 모두 유지한다.

**수정 전**

> 같은 위치에서 `onReachEnd`가 여러 번 호출될 가능성이 있을 수 있다.

**수정 후**

> 같은 위치에서 `onReachEnd`가 여러 번 호출될 수 있다.

가능성 표현의 중복만 줄였다. `항상 여러 번 호출된다`로 단정하지 않는다.

## 구조 변경을 요청받았을 때: 조치와 확인 순서로 배치한다

구조 재구성까지 요청받은 경우다. 입력 자료에는 workspace 생성의 사전 조건과 실패 조건이 모두 있다.

**수정 전**

```markdown
# React Native 관련 내용

App과 PopPangRNFeature는 Vendor/PrebuiltReactNativeFrameworks를 참조한다. 이 폴더가 없으면 tuist install과 tuist generate가 실패한다. 폴더는 scripts/download-rn-release.sh로 받는다. 그 전에 gh 로그인이 필요하다. Secrets.xcconfig도 미리 있어야 한다.
```

**수정 후**

````markdown
# workspace 만들기

`tuist generate`가 성공하려면 비밀 설정 파일과 React Native 산출물이 먼저 있어야 한다.

1. 팀에서 받은 `Projects/App/Secrets.xcconfig`와 `GoogleService-Info.plist`를 배치한다.
2. `gh auth login` 상태에서 React Native 산출물을 받는다.

   ```bash
   ./scripts/download-rn-release.sh v0.1.0
   ```

3. `tuist install`과 `tuist generate`를 실행한다.
````

독자의 목적은 React Native 구조를 이해하는 것이 아니라 workspace를 만드는 것이다. 제목에 작업을 드러내고, 준비 단계부터 실행까지 순서대로 배치했다. 문장 윤문만 요청받았다면 이런 제목·목록 변경을 자동으로 적용하지 않는다.

## 새 초안을 쓸 때: 같은 자료에서 목적에 맞는 정보를 고른다

확인한 자료가 다음과 같다.

- `mise.toml`의 `tuist = "4.115.0"`은 로컬에서 쓰는 버전이다.
- `.tuist-version`의 `4.115.0`은 CI workflow가 `mise install tuist@$(cat .tuist-version)`으로 읽는다.
- 두 값은 같아야 한다.

버전을 찾는 독자에게는 파일·값·읽는 곳을 빠르게 볼 수 있는 참조 형식이 맞다.

```markdown
## 기준 버전

Tuist 버전은 `4.115.0`으로 고정한다.

| 파일 | 값 | 읽는 곳 |
| --- | --- | --- |
| `mise.toml` | `4.115.0` | 로컬 |
| `.tuist-version` | `4.115.0` | CI |
```

버전을 설명하려고 mise 설치 과정이나 Tuist 도입 배경까지 붙이지 않는다. 두 파일을 함께 고쳐야 한다는 조건은 짧더라도 남긴다.

## 예시를 적용한 뒤 확인한다

- 코드에 없던 주체·환경·수치를 추가하지 않았는가?
- 발생 조건, 실패 경로, 가능성 표현을 보존했는가?
- 제목과 구조를 바꿀 수 있는 작업 범위인가?
- 새 초안의 설명 깊이가 독자의 목적과 맞는가?

PR을 쓸 때 정보를 고르는 방법은 [PR 작성 예시](pr-writing-examples.md)를 본다.
