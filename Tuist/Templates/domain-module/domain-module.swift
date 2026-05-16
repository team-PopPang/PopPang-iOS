import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Domain layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "16.0"),
    ],
    items: [
        .file(
            path: "Projects/Domain/\(name)Domain/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Domain/\(name)Domain/Sources/\(name).swift",
            templatePath: "Entity.stencil"
        ),
        .file(
            path: "Projects/Domain/\(name)Domain/Sources/\(name)Repository.swift",
            templatePath: "Repository.stencil"
        ),
        .file(
            path: "Projects/Domain/\(name)Domain/Tests/\(name)DomainTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
