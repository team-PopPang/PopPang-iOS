import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Shared layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/Shared/\(name)/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Shared/\(name)/Sources/\(name).swift",
            templatePath: "Module.stencil"
        ),
        .file(
            path: "Projects/Shared/\(name)/Tests/\(name)Tests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
