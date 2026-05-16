import ProjectDescription

let project = Project(
    name: "AlertFeature",
    targets: [
        .target(
            name: "AlertFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.alert",
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
            name: "AlertFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.alert",
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
            dependencies: [.target(name: "AlertFeature")]
        ),
        .target(
            name: "AlertFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.alert.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "AlertFeature")]
        ),
    ]
)
