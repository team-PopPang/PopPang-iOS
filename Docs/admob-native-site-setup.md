# AdMob Native 광고 사이트 설정 가이드

이 문서는 AdMob 계정 생성이 끝난 상태에서 Native 광고를 붙이기 위해 AdMob 사이트에서 설정해야 하는 작업을 정리한다.

범위:

- AdMob 사이트에서 앱을 등록한다.
- Native 광고 단위를 만든다.
- 개발자에게 전달할 ID를 확인한다.
- 테스트 광고, 개인정보 메시지, app-ads.txt 준비 항목을 확인한다.

코드 연동은 별도 작업으로 다룬다. 이 문서에서는 사이트 설정을 우선한다.

## PopPang 기준값

| 항목 | 값 |
| --- | --- |
| 플랫폼 | iOS |
| 앱 이름 | PopPang 또는 팝팡 |
| Bundle ID | `kr.co.poppang.PopPang` |
| 광고 형식 | Native |

## 전체 순서

1. AdMob 사이트에 앱을 등록한다.
2. 앱 ID를 복사한다.
3. Native 광고 단위를 생성한다.
4. 광고 단위 ID를 복사한다.
5. 테스트 광고 설정을 확인한다.
6. 개인정보 메시지와 app-ads.txt 준비 상태를 확인한다.
7. 개발자에게 전달할 값을 정리한다.

## 1. 앱 등록

AdMob 접속:

- https://admob.google.com

경로:

```text
Apps
> Add app
> Platform: iOS
```

### 앱이 App Store에 이미 출시된 경우

선택:

```text
Yes, it's listed on a supported app store
```

진행:

1. 앱 이름, 개발자 이름, Apple App Store URL, Apple Store ID 중 하나로 앱을 검색한다.
2. PopPang 앱을 선택한다.
3. user metrics 활성화 여부를 선택한다.
4. `Add app`을 누른다.

### 앱이 아직 App Store에 출시되지 않은 경우

선택:

```text
No
```

진행:

1. 앱 이름을 입력한다.
2. 플랫폼이 iOS인지 다시 확인한다.
3. user metrics 활성화 여부를 선택한다.
4. `Add`를 누른다.

주의:

- 미출시 앱은 테스트와 사전 설정용으로 등록할 수 있다.
- 앱이 출시되면 AdMob에서 다시 App Store listing을 연결해야 한다.
- App Store에 연결되고 AdMob readiness review가 끝나기 전까지 광고 게재가 제한될 수 있다.

## 2. 앱 ID 복사

앱 등록 후 앱 ID를 복사한다.

경로:

```text
Apps
> View all apps
> PopPang 행의 App ID 복사
```

형식:

```text
ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

용도:

- iOS 앱의 `GADApplicationIdentifier` 값으로 사용한다.
- 앱 전체를 식별하는 값이다.
- 광고 단위 ID와 다르다.

## 3. Native 광고 단위 생성

경로:

```text
Apps
> PopPang 선택
> Ad units
> Add ad unit
> Native 선택
```

광고 단위 이름은 위치와 형식을 알 수 있게 정한다.

예시:

```text
iOS_Home_Native
iOS_PopupDetail_Native
iOS_SearchResult_Native
```

추천 규칙:

- 플랫폼을 앞에 붙인다: `iOS`
- 노출 위치를 넣는다: `Home`, `PopupDetail`, `SearchResult`
- 광고 형식을 넣는다: `Native`
- 하나의 화면에 여러 위치가 있으면 번호를 붙인다: `iOS_Home_Native_01`

## 4. Native 광고 단위 옵션

Native 광고 단위 생성 중 advanced settings가 나오면 아래 기준으로 시작한다.

### Media type

초기에는 기본값 또는 이미지/비디오 모두 허용하는 설정으로 시작한다.

특정 UI에서 비디오 대응이 어렵다면 image 중심으로 제한할 수 있다. 다만 비디오를 막으면 광고 수요나 수익성에 영향이 있을 수 있으므로 디자인과 개발 구현 상태를 먼저 확인한다.

주의:

- Native 광고의 메인 이미지 또는 비디오는 `MediaView`로 렌더링해야 한다.
- 로고나 앱 아이콘은 별도 이미지 뷰로 표시할 수 있다.

### eCPM floor

초기 테스트 단계에서는 `Disabled` 또는 Google optimized 계열로 시작한다.

수동 floor는 광고 요청은 성공하지만 fill rate가 낮아질 수 있으므로, 충분한 노출 데이터가 쌓인 뒤 조정한다.

## 5. 광고 단위 ID 복사

Native 광고 단위를 만든 뒤 광고 단위 ID를 복사한다.

경로:

```text
Apps
> PopPang 선택
> Ad units
> 생성한 Native 광고 단위의 Ad unit ID 복사
```

형식:

```text
ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

용도:

- 실제 광고 요청에 사용하는 값이다.
- 화면별 광고 노출 위치마다 다른 광고 단위 ID를 쓰는 것이 관리하기 쉽다.

## 6. 테스트 광고 설정

개발 중에는 실제 광고 단위 ID로 바로 클릭 테스트하지 않는다.

우선 Google이 제공하는 iOS Native 테스트 광고 단위 ID를 사용한다.

```text
Native: ca-app-pub-3940256099942544/3986624511
Native Video: ca-app-pub-3940256099942544/2521693316
```

실제 광고 단위 ID로 테스트해야 한다면 AdMob에서 테스트 기기를 등록한다.

경로:

```text
Settings
> Test devices
> Add test device
```

확인 기준:

- iOS Simulator는 테스트 기기로 자동 처리된다.
- 실기기는 AdMob UI 또는 SDK 로그에 나온 test device ID로 등록한다.
- 테스트 광고에는 `Test mode` 표시가 붙는다.
- Native Advanced 광고는 headline에 `Test mode` 문구가 붙을 수 있다.

금지:

- 테스트 모드가 아닌 실제 광고를 개발자가 반복 클릭하지 않는다.
- QA 중에도 실제 광고 클릭으로 동작 확인하지 않는다.

## 7. 개인정보 메시지 설정

AdMob에서 개인정보 메시지는 아래 메뉴에서 설정한다.

경로:

```text
Privacy & messaging
```

확인 항목:

- GDPR 또는 유럽 경제 지역 사용자를 대상으로 하는지
- IDFA/ATT 동의 메시지가 필요한지
- 사용자가 나중에 개인정보 선택을 다시 바꿀 수 있는 진입점이 필요한지

주의:

- UMP 동의가 필요한 경우 광고 요청 전에 동의 상태를 먼저 확인해야 한다.
- 이 부분은 사이트 설정만으로 끝나지 않고 iOS 코드 연동이 필요하다.

## 8. app-ads.txt 준비

AdMob은 앱 소유권과 광고 판매 권한 확인을 위해 app-ads.txt 설정을 요구할 수 있다.

준비 항목:

1. App Store listing에 개발자 웹사이트 URL이 연결되어 있어야 한다.
2. 해당 개발자 웹사이트 루트에 `app-ads.txt`를 게시해야 한다.
3. AdMob에서 app-ads.txt 상태가 확인될 때까지 기다린다.

예시 URL:

```text
https://example.com/app-ads.txt
```

주의:

- App Store에 앱이 등록되어 있어야 AdMob이 개발자 웹사이트를 확인할 수 있다.
- AdMob이 파일을 크롤링하고 검증하는 데 시간이 걸릴 수 있다.
- app-ads.txt가 준비되지 않으면 앱 승인 또는 광고 게재가 제한될 수 있다.

## 9. 개발자에게 전달할 값

사이트 설정이 끝나면 아래 값을 개발자에게 전달한다.

| 이름 | 예시 형식 | 설명 |
| --- | --- | --- |
| AdMob App ID | `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` | 앱 전체 식별자 |
| Native Ad Unit ID | `ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy` | Native 광고 요청용 ID |
| Native Ad Unit name | `iOS_Home_Native` | AdMob 콘솔에서 관리하는 이름 |
| 테스트 광고 사용 여부 | 테스트 ID 또는 test device 등록 | 개발/QA 정책 |
| 개인정보 메시지 사용 여부 | GDPR, IDFA/ATT 등 | UMP 연동 필요 여부 |

PopPang에서는 운영 ID를 코드에 직접 하드코딩하지 않는다. 실제 코드 연동 단계에서는 `Secrets.xcconfig` 같은 로컬 설정 파일 또는 빌드 설정을 통해 주입한다.

## 10. 설정 완료 체크리스트

- [ ] AdMob에 iOS 앱을 등록했다.
- [ ] 앱 ID를 복사했다.
- [ ] Native 광고 단위를 생성했다.
- [ ] 광고 단위 ID를 복사했다.
- [ ] 광고 단위 이름에 플랫폼, 위치, 형식을 포함했다.
- [ ] 개발 중 사용할 테스트 광고 ID를 확인했다.
- [ ] 실기기 테스트가 필요하면 test device를 등록했다.
- [ ] 개인정보 메시지 필요 여부를 확인했다.
- [ ] app-ads.txt 준비 상태를 확인했다.
- [ ] 앱 출시 후 AdMob 앱과 App Store listing을 연결할 계획을 확인했다.

## 참고 문서

- [Set up an app in AdMob](https://support.google.com/admob/answer/9989980?hl=en)
- [Create a native ad unit](https://support.google.com/admob/answer/7187428?hl=en)
- [Find and copy an app ID or ad unit ID](https://support.google.com/admob/answer/7356431?hl=en)
- [Enable test ads on iOS](https://developers.google.com/admob/ios/test-ads)
- [Set up an app-ads.txt file](https://support.google.com/admob/answer/9363762?hl=en)
- [User Messaging Platform iOS quick start](https://developers.google.com/admob/ump/ios/quick-start)
