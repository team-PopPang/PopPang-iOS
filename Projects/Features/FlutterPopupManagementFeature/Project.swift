import ProjectDescription

let project = Project(
    name: "FlutterPopupManagementFeature",
    targets: [
        .target(
            name: "FlutterPopupManagementFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.flutterpopupmanagement",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "FlutterPopupManagementFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.flutterpopupmanagement",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UIUserInterfaceStyle": "Light",
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [.target(name: "FlutterPopupManagementFeature")],
            settings: .settings(
                base: [
                    "FLUTTER_SWIFT_PACKAGE_OUTPUT": "$(SRCROOT)/../../../Vendor/PopPangFlutter",
                    "FLUTTER_BUILD_MODE": "Release",
                    "FLUTTER_APPLICATION_PATH": "$(SRCROOT)/../../../PopPang-Flutter",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                ]
            )
        ),
        .target(
            name: "FlutterPopupManagementFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.flutterpopupmanagement.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "FlutterPopupManagementFeature"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ]
)
