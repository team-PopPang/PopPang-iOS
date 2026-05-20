import ProjectDescription

let project = Project(
    name: "ReviewFeature",
    targets: [
        .target(
            name: "ReviewFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.review",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .external(name: "Compound"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
        .target(
            name: "ReviewFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.review",
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
            dependencies: [.target(name: "ReviewFeature")]
        ),
        .target(
            name: "ReviewFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.review.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "ReviewFeature")]
        ),
    ]
)
