import ProjectDescription

let project = Project(
    name: "SheetKit",
    targets: [
        .target(
            name: "SheetKit",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.sheetkit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            // 다른 앱에서도 쓸 수 있도록 SwiftUI 말고는 의존하지 않는다.
            dependencies: []
        ),
        .target(
            name: "SheetKitTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.poppang.sheetkit.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "SheetKit"),
            ]
        ),
        .target(
            name: "SheetKitDemo",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.poppang.demo.sheetkit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            dependencies: [.target(name: "SheetKit")],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66",
                ]
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "SheetKit",
            shared: true,
            buildAction: .buildAction(targets: ["SheetKit", "SheetKitTests"]),
            testAction: .targets([
                .testableTarget(target: .target("SheetKitTests"))
            ])
        ),
        // scheme을 직접 정의하면 Tuist가 데모 scheme을 자동으로 만들지 않으므로 함께 둔다.
        .scheme(
            name: "SheetKitDemo",
            shared: true,
            buildAction: .buildAction(targets: ["SheetKitDemo"]),
            runAction: .runAction(executable: .target("SheetKitDemo"))
        ),
    ]
)
