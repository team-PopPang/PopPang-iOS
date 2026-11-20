import ProjectDescription

let project = Project(
    name: "PopPangRNFeature",
    packages: [
        // 팝업 제보·제보 관리 React Native 화면. PopPang-RN이 Nativepiece로 배포하는 Swift Package다.
        .remote(url: "https://github.com/team-PopPang/PopPang-RN", requirement: .exact("1.5.0")),
    ],
    targets: [
        .target(
            name: "PopPangRNFeature",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.features.poppangrn",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
                .package(product: "PopPangRN"),
            ]
        ),
        .target(
            name: "PopPangRNFeatureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.features.poppangrn.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "PopPangRNFeature"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
    ]
)
