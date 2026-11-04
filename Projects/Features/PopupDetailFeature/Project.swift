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
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "PopupDetailFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.popupdetail",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    // 본 앱과 같은 언어 목록. 없으면 iOS가 데모 앱을 영어 앱으로 보고 문구를 영어로 띄운다.
                    "CFBundleAllowMixedLocalizations": true,
                    "CFBundleLocalizations": [
                        "ko",
                        "en",
                        "ja",
                    ],
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [
                .target(name: "PopupDetailFeature"),
                .project(target: "Domain", path: "../../Domain"),
            ]
        ),
        .target(
            name: "PopupDetailFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.popupdetail.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "PopupDetailFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "PopupDetailFeatureDemo",
            shared: true,
            buildAction: .buildAction(targets: ["PopupDetailFeatureDemo"]),
            runAction: .runAction(executable: .target("PopupDetailFeatureDemo"))
        ),
    ]
)
