import Foundation

public enum ExternalLinkConfig {
    public static let notificationURLString =
        "https://deciduous-jam-49e.notion.site/29cdb9e736cf8046babdd84eb78040b3"
    public static let serviceTermsURLString =
        "https://deciduous-jam-49e.notion.site/2abdb9e736cf80cdaaa0eeeb97313523?pvs=74"
    public static let appStoreURLString =
        "https://apps.apple.com/kr/app/%ED%8C%9D%ED%8C%A1/id6753014613"
    public static let popupUniversalLinkBaseURLString =
        "https://poppang.co.kr/popup/"

    public static var notificationURL: URL {
        url(from: notificationURLString, label: "notification")
    }

    public static var serviceTermsURL: URL {
        url(from: serviceTermsURLString, label: "service terms")
    }

    public static var appStoreURL: URL {
        url(from: appStoreURLString, label: "app store")
    }

    public static var popupUniversalLinkBaseURL: URL {
        url(from: popupUniversalLinkBaseURLString, label: "popup universal link base")
    }

    public static func popupUniversalLink(popupID: String) -> URL {
        let urlString = popupUniversalLinkBaseURLString + popupID
        return url(from: urlString, label: "popup universal link")
    }

    private static func url(from string: String, label: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid \(label) URL: \(string)")
        }
        return url
    }
}
