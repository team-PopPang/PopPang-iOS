import ProjectDescription

let project = Project(
    name: "Domain",
    targets: [
        .target(
            name: "Domain",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: []
        ),
        .target(
            name: "DomainTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.domain.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "Domain")]
        ),
    ]
)
