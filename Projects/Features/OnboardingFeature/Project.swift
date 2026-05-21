import ProjectDescription

let project = Project(
    name: "OnboardingFeature",
    targets: [
        .target(
            name: "OnboardingFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.onboarding",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "OnboardingFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.onboarding",
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
            dependencies: [.target(name: "OnboardingFeature")]
        ),
        .target(
            name: "OnboardingFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.onboarding.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "OnboardingFeature")]
        ),
    ]
)
