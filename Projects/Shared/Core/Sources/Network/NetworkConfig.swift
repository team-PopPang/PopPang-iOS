import Foundation

public enum NetworkConfig {
    public static let serverURLString = "https://poppang.co.kr"
    public static let apiURLString = apiURLString(for: .v1)
    public static let imageURLString = "https://poppang.co.kr"

    public static var apiBaseURL: URL {
        apiBaseURL(for: .v1)
    }

    public static var imageBaseURL: URL {
        guard let url = URL(string: imageURLString) else {
            preconditionFailure("Invalid PopPang image base URL: \(imageURLString)")
        }
        return url
    }

    public static func apiURLString(for version: APIVersion) -> String {
        "\(serverURLString)/api/\(version.rawValue)"
    }

    public static func apiBaseURL(for version: APIVersion) -> URL {
        let urlString = apiURLString(for: version)
        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid PopPang API base URL: \(urlString)")
        }
        return url
    }
}
