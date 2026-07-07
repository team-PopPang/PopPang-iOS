import CoreText
import SwiftUI
import UIKit

public extension UIFont {
    enum SCDream: String, CaseIterable {
        case thin = "S-CoreDream-1Thin"
        case extraLight = "S-CoreDream-2ExtraLight"
        case light = "S-CoreDream-3Light"
        case regular = "S-CoreDream-4Regular"
        case medium = "S-CoreDream-5Medium"
        case bold = "S-CoreDream-6Bold"
        case extraBold = "S-CoreDream-7ExtraBold"
        case heavy = "S-CoreDream-8Heavy"
        case black = "S-CoreDream-9Black"

        fileprivate var fileName: String {
            switch self {
            case .thin: "SCDream1"
            case .extraLight: "SCDream2"
            case .light: "SCDream3"
            case .regular: "SCDream4"
            case .medium: "SCDream5"
            case .bold: "SCDream6"
            case .extraBold: "SCDream7"
            case .heavy: "SCDream8"
            case .black: "SCDream9"
            }
        }
    }

    static func scdream(_ weight: SCDream, size: CGFloat) -> UIFont {
        SCDreamFontRegistrar.registerIfNeeded()

        if let font = UIFont(name: weight.rawValue, size: size) {
            return font
        }

        assertionFailure("Failed to load S-CoreDream font: \(weight.rawValue)")
        return .systemFont(ofSize: size)
    }
}

public extension Font {
    static func scdream(_ weight: UIFont.SCDream, size: CGFloat) -> Font {
        Font(UIFont.scdream(weight, size: size))
    }
}

private enum SCDreamFontRegistrar {
    private static var isRegistered = false

    static func registerIfNeeded() {
        guard !isRegistered else { return }

        UIFont.SCDream.allCases.forEach { weight in
            registerFontIfNeeded(named: weight.fileName)
        }

        isRegistered = true
    }

    private static func registerFontIfNeeded(named name: String) {
        guard UIFont(name: name, size: 12) == nil else { return }
        guard let url = fontURL(named: name) else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    private static func fontURL(named name: String) -> URL? {
        let bundle = Bundle(for: BundleToken.self)
        return bundle.url(forResource: name, withExtension: "otf", subdirectory: "Fonts")
            ?? bundle.url(forResource: name, withExtension: "otf")
    }
}

private final class BundleToken {}
