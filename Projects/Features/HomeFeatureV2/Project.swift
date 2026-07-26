import ProjectDescription

let project = Project(
    name: "HomeFeatureV2",
    targets: [
        .target(
            name: "HomeFeatureV2",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.home.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "ADKit", path: "../../Shared/ADKit"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "HomeFeatureV2Demo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.home.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "GADApplicationIdentifier": "$(ADMOB_APP_ID)",
                    "HOME_DEMO_USER_UUID": "$(HOME_DEMO_USER_UUID)",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [
                .target(name: "HomeFeatureV2"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToManifest("Demo/HomeFeatureV2Demo.xcconfig")
                    ),
                    .release(
                        name: "Release",
                        xcconfig: .relativeToManifest("Demo/HomeFeatureV2Demo.xcconfig")
                    ),
                ]
            )
        ),
        .target(
            name: "HomeFeatureV2Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.home.v2.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "HomeFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ]
)
