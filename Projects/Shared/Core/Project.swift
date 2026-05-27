import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
        .target(
            name: "Core",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.core",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "ThirdParty", path: "../ThirdParty")
            ]
        ),
        .target(
            name: "CoreTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.core.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "Core"),
                .project(target: "ThirdParty", path: "../ThirdParty"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Core",
            shared: true,
            buildAction: .buildAction(targets: ["Core", "CoreTests"]),
            testAction: .targets([
                .testableTarget(target: .target("CoreTests"))
            ])
        ),
    ]
)
