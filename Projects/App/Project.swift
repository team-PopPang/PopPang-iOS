import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "PopPangApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "kr.co.poppang.PopPang",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleAllowMixedLocalizations": true,
                    "CFBundleDevelopmentRegion": "ko",
                    "CFBundleDisplayName": "팝팡",
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
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
                    "NSLocationAlwaysAndWhenInUseUsageDescription": "주변 팝업스토어를 지도에서 보여주고 거리 순으로 제공하기 위해 위치 정보가 필요합니다.",
                    "NSLocationAlwaysUsageDescription": "팝업스토어 정보 제공을 위해 사용자의 위치를 받습니다.",
                    "NSLocationWhenInUseUsageDescription": "주변 팝업스토어를 지도에서 보여주고 거리 순으로 제공하기 위해 위치 정보가 필요합니다.",
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
                    "UIDesignRequiresCompatibility": true, // 임시 - iOS 26에서 디자인이 깨지는 현상 방지 위해 추가, 추후 제거 필요
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
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_IDENTITY[sdk=iphoneos*]": "iPhone Developer",
                    "CODE_SIGN_STYLE": "Manual",
                    "DEVELOPMENT_TEAM": "",
                    "DEVELOPMENT_TEAM[sdk=iphoneos*]": "LGX4B4WC66",
                    "CURRENT_PROJECT_VERSION": "6",
                    "MARKETING_VERSION": "1.1.3",
                    "PROVISIONING_PROFILE_SPECIFIER": "",
                    "PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": "match Development kr.co.poppang.PopPang 1762797005",
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToManifest("Secrets.xcconfig")
                    ),
                    .release(
                        name: "Release",
                        xcconfig: .relativeToManifest("Secrets.xcconfig")
                    ),
                ]
            )
        ),
    ]
)
