import ProjectDescription

let project = Project(
    name: "MapFeature",
    targets: [
        .target(
            name: "MapFeature",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.map",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(
            name: "MapFeatureDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "kr.co.poppang.PopPang",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NMFClientID": "$(NMFClientID)",
                    "NSLocationWhenInUseUsageDescription": "현재 위치를 중심으로 지도를 이동하기 위해 위치 정보가 필요합니다.",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [
                .target(name: "MapFeature"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "Data", path: "../../Data"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToManifest("../../App/Secrets.xcconfig")
                    ),
                    .release(
                        name: "Release",
                        xcconfig: .relativeToManifest("../../App/Secrets.xcconfig")
                    ),
                ]
            )
        ),
    ]
)
