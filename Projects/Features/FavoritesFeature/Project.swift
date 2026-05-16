import ProjectDescription

let project = Project(
    name: "FavoritesFeature",
    targets: [
        .target(
            name: "FavoritesFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.favorites",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../DSKit"),
                .project(target: "Shared", path: "../../Shared"),
            ]
        ),
        .target(
            name: "FavoritesFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.favorites",
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
            dependencies: [.target(name: "FavoritesFeature")]
        ),
        .target(
            name: "FavoritesFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.favorites.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "FavoritesFeature")]
        ),
    ]
)
