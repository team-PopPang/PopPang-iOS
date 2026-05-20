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
                .project(target: "ThirdParty", path: "../Shared/ThirdParty"),
                .project(target: "Core", path: "../Shared/Core"),
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
    ]
)
