import ProjectDescription

let project = Project(
    name: "DSKit",
    targets: [
        .target(
            name: "DSKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.dskit",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
            ]
        ),
        .target(
            name: "DSKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.dskit.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "DSKit")]
        ),
    ]
)
