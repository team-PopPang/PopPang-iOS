import ProjectDescription

let project = Project(
    name: "AdFeature",
    targets: [
        .target(
            name: "AdFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.ad",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "AdFeatureInterface",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.ad.interface",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [.target(name: "AdFeature")]
        ),
        .target(
            name: "AdFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.ad",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [.target(name: "AdFeatureInterface")]
        ),
    ]
)
