// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "FirebaseAnalytics": .framework,
            "FirebaseCore": .framework,
            "FirebaseMessaging": .framework,
            "GoogleSignIn": .framework,
            "KakaoSDKAuth": .framework,
            "KakaoSDKCommon": .framework,
            "KakaoSDKShare": .framework,
            "KakaoSDKTemplate": .framework,
            "KakaoSDKUser": .framework,
            "Kingfisher": .framework,
            "Moya": .framework,
            "NMapsMap": .framework,
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
    ]
)
