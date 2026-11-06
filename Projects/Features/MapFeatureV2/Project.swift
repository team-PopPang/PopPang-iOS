import ProjectDescription

let project = Project(
    name: "MapFeatureV2",
    targets: [
        .target(
            name: "MapFeatureV2",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.map.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "SheetKit", path: "../../Shared/SheetKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "MapFeatureV2Demo",
            destinations: [.iPhone],
            product: .app,
            // 네이버 지도 키가 앱 번들 ID에 묶여 있어 데모도 앱과 같은 번들 ID를 쓴다(기존 MapFeatureDemo와 같다).
            bundleId: "kr.co.poppang.PopPang",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NMFClientID": "$(NMFClientID)",
                    "NSLocationWhenInUseUsageDescription": "현재 위치를 중심으로 지도를 이동하기 위해 위치 정보가 필요합니다.",
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
                .target(name: "MapFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToManifest("../../App/Secrets.xcconfig")
                    ),
                    .release(
                        name: "Release",
                        xcconfig: .relativeToManifest("../../App/Secrets.xcconfig")
                    ),
                ]
            )
        ),
        .target(
            name: "MapFeatureV2Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.map.v2.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "MapFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "MapFeatureV2Demo",
            shared: true,
            buildAction: .buildAction(targets: ["MapFeatureV2Demo"]),
            runAction: .runAction(executable: .target("MapFeatureV2Demo"))
        ),
    ]
)
