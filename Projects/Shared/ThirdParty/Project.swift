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
                .external(name: "ComposableArchitecture"),
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
                .external(name: "ListKit"),
                .external(name: "PopPangListKit"),
                .external(name: "Moya"),
                .external(name: "NMapsMap"),
                .external(name: "BottomSheet"),
            ],
            settings: .settings(
                base: [
                    "OTHER_LDFLAGS": "$(inherited) -ObjC",
                ]
            )
        ),
    ]
)
