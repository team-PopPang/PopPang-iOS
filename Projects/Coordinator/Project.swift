import ProjectDescription

let featureDependencies: [TargetDependency] = [
    .project(target: "AuthFeature", path: "../Features/AuthFeature"),
    .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
    .project(target: "HomeFeature", path: "../Features/HomeFeature"),
    .project(target: "SearchFeatureInterface", path: "../Features/SearchFeature"),
    .project(target: "PopupDetailFeatureInterface", path: "../Features/PopupDetailFeature"),
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
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.coordinator",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: featureDependencies + [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "DSKit", path: "../Shared/DSKit"),
            ]
        ),
        .target(
            name: "CoordinatorTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.coordinator.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "Coordinator")]
        ),
    ]
)
