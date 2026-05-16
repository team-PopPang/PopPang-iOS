import ProjectDescription

let project = Project(
    name: "ThirdParty",
    targets: [
        .target(
            name: "ThirdParty",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.thirdparty",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
                .external(name: "GoogleSignIn"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKShare"),
                .external(name: "KakaoSDKTemplate"),
                .external(name: "KakaoSDKUser"),
                .external(name: "Kingfisher"),
                .external(name: "Moya"),
                .external(name: "NMapsMap"),
            ]
        ),
        .target(
            name: "ThirdPartyTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.thirdparty.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "ThirdParty")]
        ),
    ]
)
