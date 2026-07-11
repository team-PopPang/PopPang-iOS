import ProjectDescription

let project = Project(
    name: "RootFeature",
    targets: [
        .target(
            name: "RootFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.root",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "AlertFeature", path: "../AlertFeature"),
                .project(target: "CalendarFeature", path: "../CalendarFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "FavoritesFeature", path: "../FavoritesFeature"),
                .project(target: "HomeFeature", path: "../HomeFeature"),
                .project(target: "MapFeature", path: "../MapFeature"),
                .project(target: "PopupDetailFeature", path: "../PopupDetailFeature"),
                .project(target: "PopupRequestFeature", path: "../PopupRequestFeature"),
                .project(target: "PopupRequestManagementFeature", path: "../PopupRequestManagementFeature"),
                .project(target: "ProfileFeature", path: "../ProfileFeature"),
                .project(target: "ReviewFeature", path: "../ReviewFeature"),
                .project(target: "SearchFeature", path: "../SearchFeature"),
            ]
        ),
        .target(
            name: "RootFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.root.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "RootFeature"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "Domain", path: "../../Domain"),
            ]
        ),
    ]
)
