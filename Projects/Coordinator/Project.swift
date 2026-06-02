import ProjectDescription

let featureDependencies: [TargetDependency] = [
    .project(target: "AuthFeature", path: "../Features/AuthFeature"),
    .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
    .project(target: "HomeFeature", path: "../Features/HomeFeature"),
    .project(target: "SearchFeature", path: "../Features/SearchFeature"),
    .project(target: "PopupDetailFeature", path: "../Features/PopupDetailFeature"),
    .project(target: "MapFeature", path: "../Features/MapFeature"),
    .project(target: "CalendarFeature", path: "../Features/CalendarFeature"),
    .project(target: "FavoritesFeature", path: "../Features/FavoritesFeature"),
    .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
    .project(target: "AlertFeature", path: "../Features/AlertFeature"),
    .project(target: "ReviewFeature", path: "../Features/ReviewFeature"),
]

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
            dependencies: featureDependencies + [
                .project(target: "Core", path: "../Shared/Core"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "DSKit", path: "../Shared/DSKit"),
            ]
        ),
    ]
)
