import Foundation

public enum NetworkConfig {
    public static let apiURLString = "https://poppang.co.kr/api/v1"
    public static let imageURLString = "https://poppang.co.kr"

    public static var apiBaseURL: URL {
        guard let url = URL(string: apiURLString) else {
            preconditionFailure("Invalid PopPang API base URL: \(apiURLString)")
        }
        return url
    }

    public static var imageBaseURL: URL {
        guard let url = URL(string: imageURLString) else {
            preconditionFailure("Invalid PopPang image base URL: \(imageURLString)")
        }
        return url
    }
}
