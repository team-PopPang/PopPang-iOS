# Localization Generator

이 스크립트는 `Python/localizable.csv`를 기준으로 iOS 로컬라이제이션 파일을 자동 생성합니다.

- `PopPang/Resources/en.lproj/Localizable.strings`
- `PopPang/Resources/ko.lproj/Localizable.strings`
- `PopPang/Resources/ja.lproj/Localizable.strings`
- `PopPang/Sources/Util/Constants/LocalizationKeys.swift`

즉, 번역 문구는 CSV 한 곳에서 관리하고, 앱에서 사용하는 `.strings` 파일과 `LocalizationKey` enum은 자동으로 만들어집니다.

# 장점

- CSV를 기준으로 여러 언어를 한 번에 관리할 수 있어서 언어별 파일을 따로 수정할 필요가 없습니다.
- 번역 키와 번역문이 한 화면에 정리되어 있어서 누락이나 불일치를 확인하기 쉽습니다.
- `LocalizationKeys.swift`가 자동 생성되므로 문자열 하드코딩 대신 enum 기반으로 안전하게 사용할 수 있습니다.
- 스크립트가 자신의 위치를 기준으로 경로를 계산하므로 실행 위치에 덜 민감합니다.
- 새 키를 추가할 때 CSV만 수정하면 되어 유지보수가 단순합니다.
- 번역 작업자, 개발자, 기획자가 모두 CSV 한 파일을 기준으로 볼 수 있어 협업이 편합니다.
- CSV 구조가 단순해서 AI나 번역 도구에 그대로 넘겨 다국어 초안을 만들기 쉽습니다.
- 긴 문자열 키를 직접 입력하지 않아도 되어 오타로 인한 디버깅 부담을 줄일 수 있습니다.

# 단점

- 스크립트 실행 시 `.strings` 파일과 `LocalizationKeys.swift`를 다시 생성하므로, 생성 결과를 직접 수정하면 다음 실행 때 덮어써집니다.
- CSV가 매우 커지면 파일 읽기, 생성, 검토 비용이 함께 커져 작업 속도가 느려질 수 있습니다.
- 번역 데이터가 CSV 한 파일에 모이기 때문에 충돌이 나면 한 파일에서 같이 해결해야 합니다.
- CSV 형식을 잘못 입력하면 전체 생성 결과에 영향을 줄 수 있어서 쉼표, 큰따옴표 같은 형식을 주의해야 합니다.

# CSV 형식

`localizable.csv`는 아래 형식을 따릅니다.

```csv
key,en,ko,ja
common.next,Next,다음,次へ
login.social.apple,Continue with Apple,Apple 로그인,Appleでログイン
```

- `key`: 로컬라이제이션 키
- `en`, `ko`, `ja`: 각 언어 번역값

주의:

- 값 안에 쉼표(`,`)가 들어가면 CSV 규칙에 따라 큰따옴표로 감싸야 합니다.
- 예시: `"Hello, welcome to PopPang"`

# 가상환경 설정

```bash
cd Python
python3 -m venv venv
source venv/bin/activate
```

# 라이브러리 설치

```bash
pip install -r requirements.txt
```

# 실행 방법

```bash
# 루트에서 실행
python3 Python/localization.py

# 또는 Python 폴더에서 실행
cd Python
python3 localization.py
```

안드로이드용 `strings.xml` 출력도 만들 수 있습니다.

```bash
# 루트에서 실행
python3 Python/localizationkotlin.py

# 또는 Python 폴더에서 실행
cd Python
python3 localizationkotlin.py
```

생성 위치:

- `Python/android_output/values/strings.xml`
- `Python/android_output/values-ko/strings.xml`
- `Python/android_output/values-ja/strings.xml`

# 동작 방식

1. `Python/localizable.csv`를 읽습니다.
2. 각 언어별 `Localizable.strings` 파일을 생성합니다.
3. Swift에서 사용할 `LocalizationKey` enum 파일을 생성합니다.

# Swift 사용 예시

생성된 enum을 사용하면 문자열 대신 타입 안전하게 로컬라이제이션을 적용할 수 있습니다.

```swift
Text(LocalizationKey.commonNext.localized(comment: "Next button"))
```
