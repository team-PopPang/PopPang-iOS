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
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        // .target(
        //     name: "PopupDetailFeatureDemo",
        //     destinations: [.iPhone],
        //     product: .app,
        //     bundleId: "com.poppang.demo.popupdetail",
        //     deploymentTargets: .iOS("17.0"),
        //     infoPlist: .extendingDefault(
        //         with: [
        //             "UILaunchScreen": [
        //                 "UIColorName": "",
        //                 "UIImageName": "",
        //             ],
        //         ]
        //     ),
        //     sources: ["Demo/Sources/**"],
        //     dependencies: [
        //         .target(name: "PopupDetailFeature"),
        //         .project(target: "Domain", path: "../../Domain"),
        //         .project(target: "Data", path: "../../Data"),
        //     ]
        // ),
    ]
)
