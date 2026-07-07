import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Coordinator layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/Coordinator/\(name)Coordinator/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Coordinator/\(name)Coordinator/Sources/\(name)Coordinator.swift",
            templatePath: "Coordinator.stencil"
        ),
        .file(
            path: "Projects/Coordinator/\(name)Coordinator/Sources/\(name)Route.swift",
            templatePath: "Route.stencil"
        ),
        .file(
            path: "Projects/Coordinator/\(name)Coordinator/Tests/\(name)CoordinatorTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
