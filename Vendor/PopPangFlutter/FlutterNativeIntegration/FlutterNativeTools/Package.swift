// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeTools",
    products: [
        .plugin(name: "FlutterBuildModePlugin", targets: ["Switch to Debug Mode", "Switch to Profile Mode", "Switch to Release Mode"]),
        .executable(name: "flutter-assemble-tool", targets: ["FlutterAssembleTool"]),
        .executable(name: "flutter-prebuild-tool", targets: ["FlutterPrebuildTool"])
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "FlutterToolHelper"
        ),
        .executableTarget(
            name: "FlutterAssembleTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPrebuildTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPluginTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .plugin(
            name: "Switch to Debug Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-debug", description: "Updates package to use the Debug mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Debug mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Debug"
        ),
        .plugin(
            name: "Switch to Profile Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-profile", description: "Updates package to use the Profile mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Profile mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Profile"
        ),
        .plugin(
            name: "Switch to Release Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-release", description: "Updates package to use the Release mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Release mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Release"
        )
    ]
)
