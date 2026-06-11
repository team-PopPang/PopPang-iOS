import SwiftUI
import UIKit

public enum DSKitResource {
    public static func image(_ name: String) -> Image {
        Image(name, bundle: .module)
    }

    public static func uiImage(named name: String) -> UIImage? {
        UIImage(named: name, in: .module, compatibleWith: nil)
    }
}

public enum DSKitLocalization {
    public static func localized(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: .module, comment: comment)
    }
}
