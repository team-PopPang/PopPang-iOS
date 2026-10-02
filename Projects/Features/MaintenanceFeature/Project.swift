import ProjectDescription

let project = Project(
    name: "MaintenanceFeature",
    targets: [
        .target(
            name: "MaintenanceFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.maintenance",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
        .target(
            name: "MaintenanceFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.maintenance",
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
                .target(name: "MaintenanceFeature"),
            ]
        ),
    ]
)
