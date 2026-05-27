import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "PopPangApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleAllowMixedLocalizations": true,
                    "CFBundleDevelopmentRegion": "ko",
                    "CFBundleLocalizations": [
                        "ko",
                        "en",
                        "ja",
                    ],
                    "CFBundleURLTypes": [
                        [
                            "CFBundleTypeRole": "Editor",
                            "CFBundleURLSchemes": [
                                "kakao$(KAKAO_NATIVE_APP_KEY)",
                            ],
                        ],
                        [
                            "CFBundleTypeRole": "Editor",
                            "CFBundleURLSchemes": [
                                "$(GoogleURLScheme)",
                            ],
                        ],
                    ],
                    "FirebaseAppDelegateProxyEnabled": false,
                    "GIDClientID": "$(GIDClientID)",
                    "GoogleURLScheme": "$(GoogleURLScheme)",
                    "KAKAO_NATIVE_APP_KEY": "$(KAKAO_NATIVE_APP_KEY)",
                    "LSApplicationQueriesSchemes": [
                        "kakaokompassauth",
                        "kakaolink",
                        "kakaoplus",
                    ],
                    "NMFClientID": "$(NMFClientID)",
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": false,
                    ],
                    "UIBackgroundModes": [
                        "remote-notification",
                    ],
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UIUserInterfaceStyle": "Light",
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "PopPangApp.entitlements",
            dependencies: [
                .project(target: "Coordinator", path: "../Coordinator"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Data", path: "../Data"),
                .project(target: "ThirdParty", path: "../Shared/ThirdParty"),
                .project(target: "Core", path: "../Shared/Core"),
                .project(target: "DSKit", path: "../Shared/DSKit"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66",
                    "GIDClientID": "771597909483-rq71itsts83mbjludspkr5b0btp2fek6.apps.googleusercontent.com",
                    "GoogleURLScheme": "com.googleusercontent.apps.771597909483-rq71itsts83mbjludspkr5b0btp2fek6",
                    "KAKAO_NATIVE_APP_KEY": "858c83c7bde7fec2bc6a0e0c8c023ec9",
                    "NMFClientID": "e4y23un5to",
                ]
            )
        ),
        .target(
            name: "PopPangAppTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.app.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "PopPangApp"),
                .project(target: "Domain", path: "../Domain"),
            ]
        ),
    ]
)
