import ProjectDescription

let project = Project(
    name: "AuthFeature",
    targets: [
        .target(
            name: "AuthFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.auth",
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
            name: "AuthFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.auth",
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
            dependencies: [.target(name: "AuthFeature")]
        ),
        .target(
            name: "AuthFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.auth.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "AuthFeature")]
        ),
    ]
)
