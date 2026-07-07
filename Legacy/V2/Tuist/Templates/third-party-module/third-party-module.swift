import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Scaffold a ThirdParty layer module",
    attributes: [
        name,
        .optional("bundleIdPrefix", default: "com.poppang"),
        .optional("deploymentTarget", default: "17.0"),
    ],
    items: [
        .file(
            path: "Projects/ThirdParty/\(name)SDK/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/ThirdParty/\(name)SDK/Sources/\(name)Client.swift",
            templatePath: "Client.stencil"
        ),
        .file(
            path: "Projects/ThirdParty/\(name)SDK/Tests/\(name)SDKTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
