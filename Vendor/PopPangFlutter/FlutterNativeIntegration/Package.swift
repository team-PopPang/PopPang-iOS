// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeIntegration",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterNativeIntegration", targets: ["FlutterNativeIntegration"])
    ],
    dependencies: [
        .package(name: "FlutterNativeTools", path: "FlutterNativeTools"),
        .package(name: "FlutterPluginRegistrant", path: "FlutterPluginRegistrant")
    ],
    targets: [
        .target(
            name: "FlutterNativeIntegration",
            dependencies: [
                .product(name: "FlutterPluginRegistrant", package: "FlutterPluginRegistrant")
            ]
        )
    ]
)
