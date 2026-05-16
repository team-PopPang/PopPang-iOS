import ProjectDescription

let project = Project(
    name: "OnboardingFeature",
    targets: [
        .target(
            name: "OnboardingFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.poppang.features.onboarding",
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
            name: "OnboardingFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.poppang.demo.onboarding",
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
            dependencies: [.target(name: "OnboardingFeature")]
        ),
        .target(
            name: "OnboardingFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.poppang.features.onboarding.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "OnboardingFeature")]
        ),
    ]
)
