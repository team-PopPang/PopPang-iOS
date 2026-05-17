import ProjectDescription

let project = Project(
    name: "CalendarFeature",
    targets: [
        .target(
            name: "CalendarFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.calendar",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
        .target(
            name: "CalendarFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.calendar",
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
            dependencies: [.target(name: "CalendarFeature")]
        ),
        .target(
            name: "CalendarFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.calendar.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "CalendarFeature")]
        ),
    ]
)
