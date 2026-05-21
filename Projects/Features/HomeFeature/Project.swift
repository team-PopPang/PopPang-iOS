import ProjectDescription

let project = Project(
    name: "HomeFeature",
    targets: [
        .target(
            name: "HomeFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.home",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "HomeFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.home",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [.target(name: "HomeFeature")]
        ),
        .target(
            name: "HomeFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.home.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "HomeFeature")]
        ),
    ]
)
