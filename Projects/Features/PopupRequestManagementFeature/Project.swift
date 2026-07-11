import ProjectDescription

let project = Project(
    name: "PopupRequestManagementFeature",
    targets: [
        .target(
            name: "PopupRequestManagementFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.popuprequestmanagement",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "PopupSubmissionFormFeature", path: "../PopupSubmissionFormFeature"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        // .target(
        //     name: "PopupRequestManagementFeatureDemo",
        //     destinations: [.iPhone],
        //     product: .app,
        //     bundleId: "com.poppang.demo.popuprequestmanagement",
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
        //         .target(name: "PopupRequestManagementFeature"),
        //         .project(target: "Domain", path: "../../Domain"),
        //     ]
        // ),
        .target(
            name: "PopupRequestManagementFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.popuprequestmanagement.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "PopupRequestManagementFeature"),
                .project(target: "PopupSubmissionFormFeature", path: "../PopupSubmissionFormFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ]
)
