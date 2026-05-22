import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "PopPangApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "PopPangApp.entitlements",
            dependencies: [
                .project(target: "Coordinator", path: "../Coordinator"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Data", path: "../Data"),
                .project(target: "ThirdParty", path: "../Shared/ThirdParty"),
                .project(target: "Core", path: "../Shared/Core"),
                .project(target: "DSKit", path: "../Shared/DSKit"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66",
                ]
            )
        ),
        .target(
            name: "PopPangAppTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.app.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "PopPangApp"),
                .project(target: "Domain", path: "../Domain"),
            ]
        ),
    ]
)
