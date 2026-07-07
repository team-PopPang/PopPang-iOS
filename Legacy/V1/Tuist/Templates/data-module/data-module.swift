import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a Data layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/Data/\(name)Data/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Data/\(name)Data/Sources/\(name)DTO.swift",
            templatePath: "DTO.stencil"
        ),
        .file(
            path: "Projects/Data/\(name)Data/Sources/Default\(name)Repository.swift",
            templatePath: "Repository.stencil"
        ),
        .file(
            path: "Projects/Data/\(name)Data/Tests/\(name)DataTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
