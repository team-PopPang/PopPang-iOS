import ProjectDescription

let project = Project(
    name: "MainTabFeature",
    targets: [
        .target(
            name: "MainTabFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.maintab",
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
                .project(target: "PopPangRNFeature", path: "../PopPangRNFeature"),
                .project(target: "ProfileFeature", path: "../ProfileFeature"),
                .project(target: "ReviewFeature", path: "../ReviewFeature"),
                .project(target: "SearchFeature", path: "../SearchFeature"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES": "YES",
                ]
            )
        ),
        .target(
            name: "MainTabFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.maintab.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "MainTabFeature"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "PopPangRNFeature", path: "../PopPangRNFeature"),
            ]
        ),
    ]
)
