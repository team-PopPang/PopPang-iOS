import ProjectDescription

let project = Project(
    name: "Shared",
    targets: [
        .target(
            name: "Shared",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.shared",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
            ]
        ),
        .target(
            name: "SharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.shared.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "Shared")]
        ),
    ]
)
