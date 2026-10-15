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

        fileprivate var systemWeight: UIFont.Weight {
            switch self {
            case .thin: .thin
            case .extraLight: .ultraLight
            case .light: .light
            case .regular: .regular
            case .medium: .medium
            case .bold: .bold
            case .extraBold: .heavy
            case .heavy: .heavy
            case .black: .black
            }
        }
    }

    static func scdream(_ weight: SCDream, size: CGFloat) -> UIFont {
        SCDreamFontRegistrar.registerIfNeeded()

        if let font = UIFont(name: weight.rawValue, size: size) {
            return SCDreamFallback.font(font, weight: weight)
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

/// SCDream에 없는 글자(한자, 장음 기호 ー 등)를 시스템 고딕 글꼴로 채운다.
/// 글꼴 파일이 스스로를 세리프체로 분류해서, 그대로 두면 iOS가 명조체(일본어는 히라기노 명조)로 채운다.
private enum SCDreamFallback {
    private static let cache = NSCache<NSString, UIFont>()

    /// 화면 문구의 언어. 한자를 이 언어의 글자 모양으로 고른다. 예: ja는 히라기노 고딕, ko는 Apple SD Gothic Neo
    private static let language = Bundle.module.preferredLocalizations.first ?? "ko"

    static func font(_ font: UIFont, weight: UIFont.SCDream) -> UIFont {
        let key = "\(weight.rawValue)-\(font.pointSize)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let system = UIFont.systemFont(ofSize: font.pointSize, weight: weight.systemWeight)
        let cascadeList = CTFontCopyDefaultCascadeListForLanguages(system as CTFont, [language] as CFArray) as? [UIFontDescriptor] ?? []
        let descriptor = font.fontDescriptor.addingAttributes([.cascadeList: cascadeList])
        let fallbackFont = UIFont(descriptor: descriptor, size: font.pointSize)
        cache.setObject(fallbackFont, forKey: key)
        return fallbackFont
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
