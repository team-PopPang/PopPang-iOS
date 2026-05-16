import ProjectDescription

let project = Project(
    name: "ProfileFeature",
    targets: [
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.profile",
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
            name: "ProfileFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.profile",
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
            dependencies: [.target(name: "ProfileFeature")]
        ),
        .target(
            name: "ProfileFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.profile.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "ProfileFeature")]
        ),
    ]
)
