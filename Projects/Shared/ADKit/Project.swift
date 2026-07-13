import ProjectDescription

let project = Project(
    name: "ADKit",
    targets: [
        .target(
            name: "ADKit",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.poppang.adkit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .external(name: "GoogleMobileAds"),
                .sdk(name: "JavaScriptCore", type: .framework),
            ],
            settings: .settings(
                base: [
                    // Tuist's GoogleMobileAdsTarget wrapper target does not
                    // re-export the xcframework's Objective-C symbols, so the
                    // ADKit dynamic framework must link the binary explicitly.
                    "OTHER_LDFLAGS": "$(inherited) -ObjC -framework GoogleMobileAds -framework UserMessagingPlatform",
                    // Suppresses Clang's incomplete umbrella warnings emitted by
                    // the GoogleMobileAds binary framework headers themselves.
                    "OTHER_CFLAGS": "$(inherited) -Wno-incomplete-umbrella",
                    // For Swift imports of Objective-C modules, forward the same
                    // Clang warning suppression through the Swift compiler.
                    "OTHER_SWIFT_FLAGS": "$(inherited) -Xcc -Wno-incomplete-umbrella",
                ]
            )
        ),
    ]
)
