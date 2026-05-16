import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Feature module with a demo app target",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "16.0"),
        .optional("includeInterface", default: .boolean(false)),
    ],
    items: [
        .file(
            path: "Projects/Features/\(name)Feature/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Interface/Sources/\(name)FeatureEntryView.swift",
            templatePath: "FeatureEntryView.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureRootView.swift",
            templatePath: "FeatureRootView.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Navigation/\(name)FeatureNavigator.swift",
            templatePath: "FeatureNavigator.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureView.swift",
            templatePath: "FeatureView.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureStore.swift",
            templatePath: "FeatureStore.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureAction.swift",
            templatePath: "FeatureAction.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureMutation.swift",
            templatePath: "FeatureMutation.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureState.swift",
            templatePath: "FeatureState.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Sources/Navigation/\(name)FeatureRoute.swift",
            templatePath: "FeatureRoute.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Demo/Sources/\(name)FeatureDemoApp.swift",
            templatePath: "DemoApp.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Tests/\(name)FeatureTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
