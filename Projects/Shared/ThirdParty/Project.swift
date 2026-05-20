import ProjectDescription

let project = Project(
    name: "ThirdParty",
    targets: [
        .target(
            name: "ThirdParty",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.thirdparty",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
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
                .external(name: "Compound"),
            ]
        ),
        .target(
            name: "ThirdPartyTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.thirdparty.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "ThirdParty")]
        ),
    ]
)
