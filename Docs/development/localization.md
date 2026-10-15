# 다국어 문구

PopPang 화면 문구는 모듈마다 `Resources/Localizable.xcstrings`(String Catalog)에 있어요. 한국어 원문을 키로 쓰고, 한국어(ko)·영어(en)·일본어(ja)를 지원해요. 새 문구를 추가하거나 번역을 고칠 때 이 문서를 봐요.

## 목차

- [기준](#기준)
- [코드에서 문구 쓰기](#코드에서-문구-쓰기)
- [새 문구 추가하기](#새-문구-추가하기)
- [번역하지 않는 문자열](#번역하지-않는-문자열)
- [날짜 표기](#날짜-표기)
- [글꼴](#글꼴)
- [언어별로 확인하기](#언어별로-확인하기)
- [관련 문서](#관련-문서)

## 기준

| 항목 | 기준 |
| --- | --- |
| 지원 언어 | ko(원문), en, ja. 앱 `Info.plist`의 `CFBundleLocalizations`와 같아요. |
| 다른 언어 | ko·en·ja가 아닌 언어의 기기에서는 영어로 보여요. 앱 `Info.plist`의 `CFBundleDevelopmentRegion`이 `en`이에요. |
| 카탈로그 위치 | 문구가 있는 모듈의 `Resources/Localizable.xcstrings` |
| 권한 안내 문구 | `Projects/App/Resources/InfoPlist.xcstrings` |
| 원문 언어 | `sourceLanguage`는 `ko`예요. |
| 키 | 한국어 원문을 그대로 키로 써요. 예: `"다음"`, `"리뷰 %lld개"` |
| 항목 관리 | 모든 항목을 직접 관리해요(`extractionState: manual`). ko·en·ja 값을 모두 넣어요. |
| 번역 상태 | 검토 전 번역은 `needs_review`, 검토를 마친 번역은 `translated`로 둬요. |

키 규칙의 예외는 두 곳이에요.

- `SheetKit`은 앱에 묶이지 않는 모듈이라 영어 원문과 점 표기 키(`bottomSheet.grabber.label`)를 그대로 써요. ([SheetKit](../architecture/sheet-kit.md))
- `InfoPlist.xcstrings`는 Info.plist 키(`NSLocationWhenInUseUsageDescription` 등)를 키로 써요. ko 값은 `Projects/App/Project.swift`의 `infoPlist` 값과 같아야 해요. 한쪽을 고치면 다른 쪽도 고쳐요.

모든 항목을 직접 관리하는 이유는 두 가지예요.

- Xcode가 코드에서 문구를 모아 카탈로그에 넣는 설정(`SWIFT_EMIT_LOC_STRINGS`)이 꺼져 있어요. 또 feature 모듈은 정적 프레임워크라서, Tuist가 리소스를 `<모듈>_<모듈>.bundle`이라는 별도 번들 타깃에 넣어요. 코드와 카탈로그가 다른 타깃에 있어서 설정을 켜도 자동으로 들어가지 않을 것으로 보여요(`확인 필요`: 설정을 켜고 feature 모듈을 빌드해 카탈로그가 바뀌는지 확인).
- 카탈로그에 ko 값이 없으면 빌드 결과에 `ko.lproj`가 생기지 않아요. 그러면 한국어 기기에서도 번들의 개발 언어(en)로 떨어져 영어가 나와요. 그래서 ko 값도 꼭 넣어요.

## 코드에서 문구 쓰기

문구는 항상 그 모듈의 번들(`bundle: .module`)에서 읽어요. `bundle`을 빼면 앱 본체 번들에서 찾기 때문에 번역이 나오지 않고 한국어 키가 그대로 보여요.

| 쓰는 곳 | 형식 |
| --- | --- |
| `Text` | `Text("오픈 예정 팝업", bundle: .module)` |
| `String`을 받는 곳(DSKit 구성 요소, 계산 프로퍼티 등) | `String(localized: "다음", bundle: .module)` |
| `Button` 제목 | `Button(String(localized: "확인", bundle: .module), role: .cancel) {}` |
| `alert` 제목 | `.alert(Text("알림 허용", bundle: .module), isPresented: $isPresented)` |
| UIKit | `label.text = String(localized: "광고", bundle: .module)` |

`MainOrangeButton(buttonTitle:)`, `RegionButton(text:)`, `ppBackNavigationBar(title:)`처럼 DSKit 구성 요소는 문구를 `String`으로 받아 그대로 보여 줘요. 호출하는 쪽에서 `String(localized:bundle:)`로 번역한 값을 넘겨요.

값을 끼워 넣으면 키에 형식 지정자가 들어가요.

| 코드 | 카탈로그 키 |
| --- | --- |
| `Text("리뷰 \(reviews.count)개", bundle: .module)` | `리뷰 %lld개` |
| `Text("버전: \(appVersion)", bundle: .module)` | `버전: %@` |

- 정수는 `%lld`, 문자열은 `%@`예요.
- 영어처럼 수에 따라 모양이 바뀌는 언어는 카탈로그에서 그 언어만 복수형(`one`, `other`)으로 나눠요. 예: `리뷰 %lld개` → `%lld Review` / `%lld Reviews`
- 닉네임 뒤에 붙는 문구(`님을 위한 팝업`, `님의 최근 본 검색어예요`)는 닉네임을 따로 꾸미려고 뒷부분만 키로 써요. 영어 번역은 닉네임 뒤에 이어지도록 써요. 예: `'s Popup Picks`

## 새 문구 추가하기

1. 코드에 [위 형식](#코드에서-문구-쓰기)으로 한국어 문구를 써요.
2. 같은 모듈의 `Resources/Localizable.xcstrings`를 Xcode에서 열어요.
3. `+`로 코드와 똑같은 한국어 키를 추가하고, ko·en·ja 값을 넣어요. ko 값은 키와 같게 넣어요.
4. 번역을 아직 검토하지 않았다면 en·ja를 `Needs Review`로 표시해요.
5. 해당 언어로 앱을 실행해 확인해요. ([언어별로 확인하기](#언어별로-확인하기))

모듈에 카탈로그가 처음이면 먼저 아래를 해요.

1. `Resources/Localizable.xcstrings`를 만들어요.
2. 모듈 `Project.swift`의 타깃에 `resources: ["Resources/**"]`를 추가해요. 앱 타깃은 `resources`에 파일을 하나씩 적어요.
3. `tuist generate`를 실행해요. Tuist가 `Bundle.module`을 만들어요.

`make module LAYER=feature`로 만든 모듈에는 카탈로그와 `resources`가 처음부터 들어 있어요.

`bundle`을 빠뜨린 한국어 `Text`는 아래 명령으로 찾을 수 있어요.

```bash
grep -rnE 'Text\("[^"]*[가-힣]' Projects --include='*.swift' | grep -v '/Derived/\|/Tests/\|/Demo/\|bundle:'
```

## 번역하지 않는 문자열

아래는 화면 문구가 아니라서 카탈로그에 넣지 않아요.

| 종류 | 예 |
| --- | --- |
| 로그와 개발자용 메시지 | `Logger.d(...)`, `print(...)`, `fatalError(...)` 메시지 |
| 미리보기와 목 데이터 | `#Preview` 이름, `previewValue`, Domain 엔티티의 미리보기 값 |
| 서버 값 | 지역·구 이름과 `전체`, API 파라미터(`PopupSubmissionListFilter` 원시값 등) |
| 오류 메시지 | `error.localizedDescription`으로 보여 주는 Domain·네트워크 오류 문구 |

- 지역 이름과 `전체`는 서버가 내려 주는 값이고 요청 파라미터로도 쓰여서 번역하지 않아요. 영어·일본어에서도 한국어로 보여요.
- 오류 메시지는 서버·네트워크 오류 처리와 함께 정해야 해서 이번 범위에 넣지 않았어요(`확인 필요`: 오류 문구를 화면에서 어떻게 보여 줄지 정한 뒤 옮겨요).

## 날짜 표기

화면에 보여 주는 날짜는 화면 문구와 같은 언어로 써요. 언어마다 순서와 단위가 달라서, 형식 문자열을 직접 쓰지 않고 템플릿을 써요.

```swift
let formatter = DateFormatter()
formatter.locale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "ko")
formatter.setLocalizedDateFormatFromTemplate("dE")  // 15일 (목), Thu 15, 15日(木)
```

- `Locale.current`는 앱 언어가 아니라 기기의 지역 설정을 따라요. 지역이 `ko_KR`인 시뮬레이터에서 `-AppleLanguages (en)`으로 실행하면, 문구는 영어인데 `Locale.current`로 만든 날짜는 한국어로 나와요. 그래서 문구를 읽는 번들이 고른 언어(`Bundle.module.preferredLocalizations`)로 정해요.
- 서버와 주고받는 날짜(`yyyy-MM-dd`)나 숫자만 쓰는 형식(`yy.MM.dd`)은 `ko_KR`을 고정해 그대로 둬요.

## 글꼴

SCDream 글꼴에는 한자와 장음 기호(`ー`)가 없어요. `UIFont.scdream`이 빠진 글자를 화면 언어에 맞는 시스템 고딕 글꼴로 채워요.

| 화면 언어 | 빠진 글자를 채우는 글꼴 |
| --- | --- |
| ja | 히라기노 고딕 |
| ko | Apple SD Gothic Neo |

- 글꼴 파일이 스스로를 세리프체로 분류해요. 그래서 이 처리가 없으면 iOS가 빠진 글자를 명조체(일본어는 히라기노 명조)로 채워요.
- 앱의 모든 글꼴이 `UIFont.scdream`을 거치므로 화면 코드에서 따로 할 일은 없어요.

## 언어별로 확인하기

- Xcode: scheme의 Run → Options → App Language에서 언어를 골라 실행해요.
- 시뮬레이터: 앱을 설치한 뒤 언어를 지정해 실행해요.

  ```bash
  xcrun simctl launch --terminate-running-process <시뮬레이터 UDID> kr.co.poppang.PopPang -AppleLanguages "(en)"
  ```

지원하지 않는 언어(예: 프랑스어)만 쓰는 기기에서는 앱 전체가 영어로 나와요. 앱 본체의 개발 언어(`Projects/App/Project.swift`의 `CFBundleDevelopmentRegion`)와 모듈 번들의 개발 언어(Tuist 기본값)가 모두 `en`이라서예요.

권한 안내처럼 앱 본체에 있는 문구는 화면에서 확인하기 어려워요. 실행 중인 앱에 디버거를 붙여 실제로 고른 문구를 읽어요.

```bash
xcrun lldb -p <앱 pid> --batch -o 'expr -l objc -O -- [[NSBundle mainBundle] localizedStringForKey:@"NSLocationWhenInUseUsageDescription" value:@"MISSING" table:@"InfoPlist"]' -o detach
```

## 관련 문서

- [모듈 구조](../architecture/modules.md)
- [디자인 시스템](../architecture/design-system.md)
- [SheetKit](../architecture/sheet-kit.md)
- [Tuist 설치와 실행](tuist.md)
