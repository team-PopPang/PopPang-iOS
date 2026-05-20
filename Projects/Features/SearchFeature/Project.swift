import ProjectDescription

let project = Project(
    name: "SearchFeature",
    targets: [
        .target(
            name: "SearchFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.search",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Compound"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "SearchFeatureInterface",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.search.interface",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [.target(name: "SearchFeature")]
        ),
        .target(
            name: "SearchFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.search",
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
            dependencies: [.target(name: "SearchFeatureInterface")]
        ),
        .target(
            name: "SearchFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.search.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "SearchFeature")]
        ),
    ]
)
