import ProjectDescription

let project = Project(
    name: "CalendarFeature",
    targets: [
        .target(
            name: "CalendarFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.calendar",
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
            name: "CalendarFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.calendar",
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
                .target(name: "CalendarFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Data", path: "../../Data"),
            ]
        ),
    ]
)
