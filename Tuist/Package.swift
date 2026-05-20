// swift-tools-version: 6.0
// xcodebuild -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
import PackageDescription

#if TUIST
    import ProjectDescription

    // 링크 기본 개념
    // - link = 우리 타깃이 외부 라이브러리 코드를 자기 빌드 결과물에 연결하는 과정
    // - static link = 빌드 시점에 라이브러리 코드가 앱/상위 모듈 바이너리에 합쳐진다
    // - dynamic link = 빌드 시점에는 참조만 연결하고, 실행 시점에 별도 framework를 로드한다
    //
    // product type 개념
    // - `.staticFramework`
    //   - framework 형태로 보이지만 실제 코드는 링크 시점에 상위 타깃 쪽으로 합쳐진다
    //   - 런타임에 따로 로드할 framework 수가 적어서 보통 더 단순하고 안전한 편이다
    //   - 빌드 속도: 첫 빌드나 "수정 없음" 재빌드는 대체로 단순한 편이지만, 증분 빌드에서는 상위 타깃 재링크 부담이 커질 수 있다
    //   - 런타임 속도: 별도 dynamic loader 비용이 적어서 앱 시작에 유리한 편이다
    //   - 파일 크기: 최종 앱 실행 파일은 커질 수 있지만, 별도 dynamic framework bundle은 줄어든다
    // - `.framework`
    //   - dynamic framework
    //   - 실행 시점에 앱이 framework를 별도로 로드한다
    //   - 모듈 경계를 분리하기 쉬울 수 있지만, 패키지가 기대한 링크 방식과 다르면 의존 전파가 깨질 수 있다
    //   - 빌드 속도: 일부 모듈만 자주 수정하는 큰 구조에서는 증분 빌드에 유리할 수 있지만, 첫 빌드나 수정 없는 재빌드는 embed/sign/load 비용 때문에 불리할 수 있다
    //   - 런타임 속도: 앱 시작 시 dynamic loader가 framework를 추가로 읽어야 해서 더 느려질 수 있다
    //   - 파일 크기: 메인 실행 파일은 작아질 수 있지만, 앱 번들 안의 framework 산출물은 늘어난다
    //
    // 우리 모듈 기준 원칙
    // - 현재 `Projects/*/Project.swift`의 `Feature`, `FeatureInterface`, `Core`, `Domain`, `Data`, `DSKit`, `Shared`, `ThirdParty`, `Coordinator`는 전부 `.framework`로 운영 중이다.
    // - 이유: 마이그레이션 단계에서 모듈 경계와 `import` 관계를 명확히 유지하고, Demo/App/Test 조립을 단순하게 가져가기 쉽기 때문이다.
    // - `Feature`, `Core`, `Interface`처럼 다른 모듈이나 Demo/App 타깃에서 직접 import해서 쓰는 모듈은 현재처럼 `.framework`를 우선한다.
    // - 반대로 외부 공개 경계가 거의 없는 leaf 유틸 모듈이고, 런타임 로드 비용이나 번들 단순화가 더 중요하면 `.staticFramework`를 검토할 수 있다.
    // - 특히 feature 수가 많아지면 dynamic framework 수도 함께 늘기 쉬워서, 앱 시작 속도와 런타임 단순화를 위해 leaf feature를 `.staticFramework`로 바꿀 고민이 생길 수 있다.
    // - 즉 static을 쓰는 대표 이유는 "모듈은 잘게 나누되, 실행 시점에 따로 로드할 framework 수는 줄이고 싶다"는 데 있다.
    // - 다만 internal module도 static으로 바꿀 때 transitive dependency, resource 처리, preview/demo/test 조립이 깨지지 않는지 꼭 빌드로 확인한다.
    //
    // `PackageSettings()`만 쓰면 product type override를 하지 않는다.
    // Tuist 공식 문서 예시/레퍼런스 기준 기본 product type은 `.staticFramework`다.
    // 즉 여기에 없는 제품은 우선 `.staticFramework` 기준으로 통합된다고 이해하면 된다.
    //
    // product type 요약
    // - `.framework`: dynamic framework.
    //   실행 시점에 앱이 framework를 별도로 로드한다.
    //   장점: 모듈이 분리되어 `import`/링크 관계가 단순해질 때가 있다.
    //   단점: 패키지가 원래 기대한 정적 링크 방식과 다르면 내부 auto-link가 깨질 수 있다.
    // - `.staticFramework`: static framework.
    //   framework 모양으로 보이지만 링크 시점에 바이너리가 앱/상위 모듈에 합쳐진다.
    //   장점: 기본값으로 무난하고 런타임 의존성이 적다.
    //   단점: 어떤 패키지는 다른 패키지에서 모듈로 참조할 때 dynamic framework 쪽이 더 안정적일 수 있다.
    //
    // 원칙
    // 1. 기본은 가능한 한 여기에 아무것도 추가하지 않는다.
    // 2. 실제로 `no such module`, explicit module open 실패, 링크 실패가 날 때만 최소 제품만 override 한다.
    // 3. override는 "문제 나는 제품"과 "그 제품이 직접 기대하는 하위 제품"까지만 좁게 건다.
    //
    // 언제 `.framework`를 쓰는가
    // - 패키지 A가 패키지 B를 framework 모듈처럼 참조해야 해서 static 기본값으로는 import/link가 깨질 때
    // - 예: 현재 `Moya`가 `Alamofire` 모듈을 못 찾아서 둘 다 `.framework`로 고정했다.
    //
    // 언제 `.staticFramework`를 쓰는가
    // - 패키지가 원래 정적 링크 쪽에 더 잘 맞고, dynamic으로 바꾸면 내부 링크가 깨질 때
    // - Firebase 계열처럼 binary/auto-link 의존이 많은 패키지는 특히 주의한다.
    //
    // 왜 문제가 생기나
    // - 패키지가 기대한 링크 방식(static/dynamic)을 바꾸면 transitive dependency 전파 방식이 달라진다.
    // - 그 결과 `swiftCompatibility*`, `UIUtilities`, `no such module`, explicit module open 실패 같은 에러가 날 수 있다.
    // - 실제로 이 프로젝트에서는 Firebase/GoogleSignIn을 `.framework`로 강제했을 때 위 문제가 재현됐다.
    //
    // 현재 정책
    // - Firebase, GoogleSignIn: override하지 않고 기본값 유지
    //   - 이유: 이 둘을 `.framework`로 강제했을 때 `swiftCompatibility*`, `UIUtilities` 같은 auto-link 관련 링크 에러가 실제로 재현됐다.
    //   - 즉 SDK가 기대한 기본 링크 구성을 깨지 않는 쪽이 더 안전했다.
    //   - Firebase 공식 문서도 SPM 배포는 static only라고 안내한다:
    //     https://firebase.google.com/docs/ios/link-firebase-static-dynamic
    //   - GoogleSignIn 공식 설치 문서는 SPM 사용법만 안내하고 static/dynamic override 지침은 명시하지 않았다:
    //     https://developers.google.com/identity/sign-in/ios/start-integrating
    //   - 그래서 GoogleSignIn은 "공식적으로 `.framework`로 바꾸라"는 근거가 없고, 이 프로젝트에서는 실제 빌드 재현 결과를 우선해 기본값 유지로 둔다.
    // - Moya, Alamofire: `.framework` 유지
    //   - 이유: 기본값으로 둘 때 `Moya` 쪽에서 `Alamofire`를 못 찾는 모듈 해석 문제가 실제로 재현됐다.
    let packageSettings = PackageSettings(
        productTypes: [
            "Alamofire": .framework,
            "Compound": .framework,
            "CompoundCore": .framework,
            "Moya": .framework,
        ]
    )
#endif

let package = Package(
    name: "PopPang",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.6.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", exact: "9.0.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", exact: "2.26.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", exact: "8.6.2"),
        .package(url: "https://github.com/Moya/Moya.git", exact: "15.0.3"),
        .package(url: "https://github.com/navermaps/SPM-NMapsMap", exact: "3.23.0"),
        .package(url: "https://github.com/indextrown/Compound", exact: "1.0.3"),
    ]
)
