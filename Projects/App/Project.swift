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
                    "ADMOB_NATIVE_AD_UNIT_ID": "$(ADMOB_NATIVE_AD_UNIT_ID)",
                    "GADApplicationIdentifier": "$(ADMOB_APP_ID)",
                    "AIRBRIDGE_APP_NAME": "$(AIRBRIDGE_APP_NAME)",
                    "AIRBRIDGE_SDK_TOKEN": "$(AIRBRIDGE_SDK_TOKEN)",
                    // ATT
                    "NSUserTrackingUsageDescription": "맞춤형 광고 제공과 광고 성과 측정을 위해 앱 사용 정보가 사용될 수 있습니다.",
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
                    "SKAdNetworkItems": [
                        ["SKAdNetworkIdentifier": "cstr6suwn9.skadnetwork"],
                        ["SKAdNetworkIdentifier": "4fzdc2evr5.skadnetwork"],
                        ["SKAdNetworkIdentifier": "2fnua5tdw4.skadnetwork"],
                        ["SKAdNetworkIdentifier": "ydx93a7ass.skadnetwork"],
                        ["SKAdNetworkIdentifier": "p78axxw29g.skadnetwork"],
                        ["SKAdNetworkIdentifier": "v72qych5uu.skadnetwork"],
                        ["SKAdNetworkIdentifier": "ludvb6z3bs.skadnetwork"],
                        ["SKAdNetworkIdentifier": "cp8zw746q7.skadnetwork"],
                        ["SKAdNetworkIdentifier": "3sh42y64q3.skadnetwork"],
                        ["SKAdNetworkIdentifier": "c6k4g5qg8m.skadnetwork"],
                        ["SKAdNetworkIdentifier": "s39g8k73mm.skadnetwork"],
                        ["SKAdNetworkIdentifier": "wg4vff78zm.skadnetwork"],
                        ["SKAdNetworkIdentifier": "3qy4746246.skadnetwork"],
                        ["SKAdNetworkIdentifier": "f38h382jlk.skadnetwork"],
                        ["SKAdNetworkIdentifier": "hs6bdukanm.skadnetwork"],
                        ["SKAdNetworkIdentifier": "mlmmfzh3r3.skadnetwork"],
                        ["SKAdNetworkIdentifier": "v4nxqhlyqp.skadnetwork"],
                        ["SKAdNetworkIdentifier": "wzmmz9fp6w.skadnetwork"],
                        ["SKAdNetworkIdentifier": "su67r6k2v3.skadnetwork"],
                        ["SKAdNetworkIdentifier": "yclnxrl5pm.skadnetwork"],
                        ["SKAdNetworkIdentifier": "t38b2kh725.skadnetwork"],
                        ["SKAdNetworkIdentifier": "7ug5zh24hu.skadnetwork"],
                        ["SKAdNetworkIdentifier": "gta9lk7p23.skadnetwork"],
                        ["SKAdNetworkIdentifier": "vutu7akeur.skadnetwork"],
                        ["SKAdNetworkIdentifier": "y5ghdn5j9k.skadnetwork"],
                        ["SKAdNetworkIdentifier": "v9wttpbfk9.skadnetwork"],
                        ["SKAdNetworkIdentifier": "n38lu8286q.skadnetwork"],
                        ["SKAdNetworkIdentifier": "47vhws6wlr.skadnetwork"],
                        ["SKAdNetworkIdentifier": "kbd757ywx3.skadnetwork"],
                        ["SKAdNetworkIdentifier": "9t245vhmpl.skadnetwork"],
                        ["SKAdNetworkIdentifier": "a2p9lx4jpn.skadnetwork"],
                        ["SKAdNetworkIdentifier": "22mmun2rn5.skadnetwork"],
                        ["SKAdNetworkIdentifier": "44jx6755aq.skadnetwork"],
                        ["SKAdNetworkIdentifier": "k674qkevps.skadnetwork"],
                        ["SKAdNetworkIdentifier": "4468km3ulz.skadnetwork"],
                        ["SKAdNetworkIdentifier": "2u9pt9hc89.skadnetwork"],
                        ["SKAdNetworkIdentifier": "8s468mfl3y.skadnetwork"],
                        ["SKAdNetworkIdentifier": "klf5c3l5u5.skadnetwork"],
                        ["SKAdNetworkIdentifier": "ppxm28t8ap.skadnetwork"],
                        ["SKAdNetworkIdentifier": "kbmxgpxpgc.skadnetwork"],
                        ["SKAdNetworkIdentifier": "uw77j35x4d.skadnetwork"],
                        ["SKAdNetworkIdentifier": "578prtvx9j.skadnetwork"],
                        ["SKAdNetworkIdentifier": "4dzt52r2t5.skadnetwork"],
                        ["SKAdNetworkIdentifier": "tl55sbb4fm.skadnetwork"],
                        ["SKAdNetworkIdentifier": "c3frkrj4fj.skadnetwork"],
                        ["SKAdNetworkIdentifier": "e5fvkxwrpn.skadnetwork"],
                        ["SKAdNetworkIdentifier": "8c4e2ghe7u.skadnetwork"],
                        ["SKAdNetworkIdentifier": "3rd42ekr43.skadnetwork"],
                        ["SKAdNetworkIdentifier": "97r2b46745.skadnetwork"],
                        ["SKAdNetworkIdentifier": "3qcr597p9d.skadnetwork"],
                    ],
                    "UIBackgroundModes": [
                        "remote-notification",
                    ],
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UIDesignRequiresCompatibility": true, // 임시 - iOS 26에서 디자인이 깨지는 현상 방지 위해 추가, 추후 제거 필요
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
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
