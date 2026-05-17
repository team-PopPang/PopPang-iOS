import ProjectDescription

let project = Project(
    name: "SearchFeature",
    targets: [
        .target(
            name: "SearchFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.search",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
        .target(
            name: "SearchFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.search.interface",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [.target(name: "SearchFeature")]
        ),
        .target(
            name: "SearchFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.search",
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
            dependencies: [.target(name: "SearchFeatureInterface")]
        ),
        .target(
            name: "SearchFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.search.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "SearchFeature")]
        ),
    ]
)
