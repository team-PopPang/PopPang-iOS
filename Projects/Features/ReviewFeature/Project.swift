import ProjectDescription

let project = Project(
    name: "ReviewFeature",
    targets: [
        .target(
            name: "ReviewFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.review",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
        .target(
            name: "ReviewFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.review",
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
            dependencies: [.target(name: "ReviewFeature")]
        ),
        .target(
            name: "ReviewFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.review.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "ReviewFeature")]
        ),
    ]
)
