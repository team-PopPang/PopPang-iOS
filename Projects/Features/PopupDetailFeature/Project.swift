import ProjectDescription

let project = Project(
    name: "PopupDetailFeature",
    targets: [
        .target(
            name: "PopupDetailFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.popupdetail",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "PopupDetailFeatureInterface",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.popupdetail.interface",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [.target(name: "PopupDetailFeature")]
        ),
        .target(
            name: "PopupDetailFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.popupdetail",
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
            dependencies: [.target(name: "PopupDetailFeatureInterface")]
        ),
        .target(
            name: "PopupDetailFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.popupdetail.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: "PopupDetailFeature")]
        ),
    ]
)
