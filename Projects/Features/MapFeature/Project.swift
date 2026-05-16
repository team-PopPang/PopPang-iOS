import ProjectDescription

let project = Project(
    name: "MapFeature",
    targets: [
        .target(
            name: "MapFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.map",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../DSKit"),
                .project(target: "Shared", path: "../../Shared"),
            ]
        ),
        .target(
            name: "MapFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.map",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [.target(name: "MapFeature")]
        ),
        .target(
            name: "MapFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.map.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "MapFeature")]
        ),
    ]
)
