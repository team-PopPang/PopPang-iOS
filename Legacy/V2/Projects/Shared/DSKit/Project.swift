import ProjectDescription

let project = Project(
    name: "DSKit",
    targets: [
        .target(
            name: "DSKit",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.dskit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .project(target: "ThirdParty", path: "../ThirdParty"),
            ]
        ),
        .target(
            name: "DSKitDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.dskit",
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
            dependencies: [.target(name: "DSKit")],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66",
                ]
            )
        ),
    ]
)
