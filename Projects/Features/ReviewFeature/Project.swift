import ProjectDescription

let project = Project(
    name: "ReviewFeature",
    targets: [
        .target(
            name: "ReviewFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.review",
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
        // .target(
        //     name: "ReviewFeatureDemo",
        //     destinations: [.iPhone],
        //     product: .app,
        //     bundleId: "com.poppang.demo.review",
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
        //     dependencies: [.target(name: "ReviewFeature")]
        // ),
    ]
)
