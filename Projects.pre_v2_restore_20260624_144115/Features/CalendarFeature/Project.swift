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
                .target(name: "CalendarFeatureInterface"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "CalendarFeatureInterface",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.calendar.interface",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
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
                .target(name: "CalendarFeatureInterface"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Data", path: "../../Data"),
            ]
        ),
    ]
)
