import ProjectDescription

let project = Project(
    name: "AuthFeatureV2",
    targets: [
        .target(
            name: "AuthFeatureV2",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.auth.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "AuthFeatureV2Demo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.auth.v2",
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
                .target(name: "AuthFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
            ]
        ),
        .target(
            name: "AuthFeatureV2Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.auth.v2.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "AuthFeatureV2"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "AuthFeatureV2Demo",
            shared: true,
            buildAction: .buildAction(targets: ["AuthFeatureV2Demo"]),
            runAction: .runAction(executable: .target("AuthFeatureV2Demo"))
        ),
    ]
)
