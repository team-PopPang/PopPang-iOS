import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Core layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/Core/\(name)/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Core/\(name)/Sources/\(name).swift",
            templatePath: "Module.stencil"
        ),
        .file(
            path: "Projects/Core/\(name)/Tests/\(name)Tests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
