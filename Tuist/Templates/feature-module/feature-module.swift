import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Feature module with a demo app target",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
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
            path: "Projects/Features/\(name)Feature/Sources/Presentation/\(name)FeatureView.swift",
            templatePath: "FeatureView.stencil"
        ),
        .file(
            path: "Projects/Features/\(name)Feature/Demo/Sources/\(name)FeatureDemoApp.swift",
            templatePath: "DemoApp.stencil"
        ),
    ]
)
