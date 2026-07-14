import ProjectDescription

let project = Project(
    name: "PopPangRNFeature",
    packages: [
        .local(path: "../../../Vendor/PrebuiltReactNativeFrameworks"),
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
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
                .package(product: "PrebuiltReactNativeFrameworks"),
            ]
        ),
    ]
)
