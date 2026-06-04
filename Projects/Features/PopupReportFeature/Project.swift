import ProjectDescription

let project = Project(
    name: "PopupReportFeature",
    targets: [
        .target(
            name: "PopupReportFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.popupreport",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "PopupReportFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.popupreport",
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
                .target(name: "PopupReportFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Data", path: "../../Data"),
            ]
        ),
    ]
)
