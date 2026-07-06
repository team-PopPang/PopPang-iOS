// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

// Profile

let package = Package(
    name: "FlutterPluginRegistrant",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterPluginRegistrant", type: .static, targets: ["FlutterPluginRegistrant"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "Packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .target(name: "App")
            ]
        ),
        .binaryTarget(
            name: "App",
            path: "Frameworks/App.xcframework"
        )
    ]
)
