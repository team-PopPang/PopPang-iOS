import ProjectDescription

let project = Project(
    name: "CalendarFeatureV2",
    targets: [
        .target(
            name: "CalendarFeatureV2",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.calendar.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "CalendarFeatureV2Demo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.calendar.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    // 본 앱과 같은 언어 목록. 없으면 iOS가 데모 앱을 영어 앱으로 보고 문구를 영어로 띄운다.
                    "CFBundleAllowMixedLocalizations": true,
                    "CFBundleLocalizations": [
                        "ko",
                        "en",
                        "ja",
                    ],
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [
                .target(name: "CalendarFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
            ]
        ),
        .target(
            name: "CalendarFeatureV2Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.calendar.v2.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "CalendarFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ]
)
