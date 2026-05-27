import ProjectDescription

let project = Project(
    name: "Data",
    targets: [
        .target(
            name: "Data",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.data",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Shared/Core"),
                .project(target: "ThirdParty", path: "../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "DataTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.data.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "Data")]
        ),
    ],
    schemes: [
        .scheme(
            name: "Data",
            shared: true,
            buildAction: .buildAction(targets: ["Data", "DataTests"]),
            testAction: .targets([
                .testableTarget(target: .target("DataTests"))
            ])
        ),
    ]
)
