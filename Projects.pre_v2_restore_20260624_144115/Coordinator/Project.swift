import ProjectDescription

let project = Project(
    name: "Coordinator",
    targets: [
        .target(
            name: "Coordinator",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.coordinator",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "AlertFeature", path: "../Features/AlertFeature"),
                .project(target: "AlertFeatureInterface", path: "../Features/AlertFeature"),
                .project(target: "CalendarFeature", path: "../Features/CalendarFeature"),
                .project(target: "CalendarFeatureInterface", path: "../Features/CalendarFeature"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "FavoritesFeature", path: "../Features/FavoritesFeature"),
                .project(target: "FavoritesFeatureInterface", path: "../Features/FavoritesFeature"),
                .project(target: "HomeFeature", path: "../Features/HomeFeature"),
                .project(target: "HomeFeatureInterface", path: "../Features/HomeFeature"),
                .project(target: "MapFeature", path: "../Features/MapFeature"),
                .project(target: "MapFeatureInterface", path: "../Features/MapFeature"),
                .project(target: "PopupDetailFeature", path: "../Features/PopupDetailFeature"),
                .project(target: "PopupDetailFeatureInterface", path: "../Features/PopupDetailFeature"),
                .project(target: "PopupRequestFeature", path: "../Features/PopupRequestFeature"),
                .project(target: "PopupRequestFeatureInterface", path: "../Features/PopupRequestFeature"),
                .project(target: "PopupRequestManagementFeature", path: "../Features/PopupRequestManagementFeature"),
                .project(target: "PopupRequestManagementFeatureInterface", path: "../Features/PopupRequestManagementFeature"),
                .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
                .project(target: "ProfileFeatureInterface", path: "../Features/ProfileFeature"),
                .project(target: "ReviewFeature", path: "../Features/ReviewFeature"),
                .project(target: "SearchFeature", path: "../Features/SearchFeature"),
                .project(target: "SearchFeatureInterface", path: "../Features/SearchFeature"),
                .external(name: "BottomSheet"),
            ]
        ),
    ]
)
