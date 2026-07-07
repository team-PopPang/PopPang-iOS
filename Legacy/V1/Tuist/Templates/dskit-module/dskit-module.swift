import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a DSKit module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/DSKit/\(name)/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/DSKit/\(name)/Sources/\(name).swift",
            templatePath: "Module.stencil"
        ),
        .file(
            path: "Projects/DSKit/\(name)/Tests/\(name)Tests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
