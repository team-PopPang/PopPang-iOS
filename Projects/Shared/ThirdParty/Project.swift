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
                .external(name: "Compound"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
                .external(name: "GoogleMobileAds"),
                .external(name: "GoogleSignIn"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKShare"),
                .external(name: "KakaoSDKTemplate"),
                .external(name: "KakaoSDKUser"),
                .external(name: "Kingfisher"),
                .external(name: "ListKit"),
                .external(name: "Moya"),
                .external(name: "NMapsMap"),
                .external(name: "BottomSheet"),
                .sdk(name: "JavaScriptCore", type: .framework),

                // AirBridge관련
                .external(name: "Airbridge"),
                .sdk(name: "AdSupport", type: .framework, status: .optional),
                .sdk(name: "AdServices", type: .framework, status: .optional),
                .sdk(name: "CoreTelephony", type: .framework, status: .optional),
                .sdk(name: "StoreKit", type: .framework, status: .optional),
                .sdk(name: "AppTrackingTransparency", type: .framework, status: .optional),
                .sdk(name: "WebKit", type: .framework, status: .optional),
            ],
            settings: .settings(
                base: [
                    "OTHER_LDFLAGS": "$(inherited) -ObjC",
                ]
            )
        ),
    ]
)
