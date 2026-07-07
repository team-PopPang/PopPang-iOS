import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold an App layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/App/\(name)/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/App/\(name)/Sources/\(name).swift",
            templatePath: "Module.stencil"
        ),
        .file(
            path: "Projects/App/\(name)/Tests/\(name)Tests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
