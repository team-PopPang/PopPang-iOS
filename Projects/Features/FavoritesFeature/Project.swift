import ProjectDescription

let project = Project(
    name: "FavoritesFeature",
    targets: [
        .target(
            name: "FavoritesFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.favorites",
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
            name: "FavoritesFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.favorites",
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
                .target(name: "FavoritesFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Data", path: "../../Data"),
            ]
        ),
        .target(
            name: "FavoritesFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.favorites.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "FavoritesFeature"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
            ]
        ),
    ]
)
