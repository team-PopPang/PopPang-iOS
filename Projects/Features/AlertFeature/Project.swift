import ProjectDescription

let project = Project(
    name: "AlertFeature",
    targets: [
        .target(
            name: "AlertFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.alert",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "AlertFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.alert",
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
            dependencies: [
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "AlertFeatureDemo",
            shared: true,
            buildAction: .buildAction(targets: ["AlertFeatureDemo"]),
            runAction: .runAction(executable: .target("AlertFeatureDemo"))
        ),
    ]
)
