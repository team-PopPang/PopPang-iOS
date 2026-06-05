import SwiftUI
import UIKit

public extension UINavigationBar {
    static func configureAppearance() {
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithOpaqueBackground()
        defaultAppearance.backgroundColor = .clear
        defaultAppearance.shadowColor = .clear

        let backAppearance = UIBarButtonItemAppearance()
        let hiddenBackTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 0.1),
            .foregroundColor: UIColor.clear,
        ]
        backAppearance.normal.titleTextAttributes = hiddenBackTitleAttributes
        backAppearance.highlighted.titleTextAttributes = hiddenBackTitleAttributes
        backAppearance.disabled.titleTextAttributes = hiddenBackTitleAttributes
        backAppearance.focused.titleTextAttributes = hiddenBackTitleAttributes
        defaultAppearance.backButtonAppearance = backAppearance

        defaultAppearance.titleTextAttributes = [
            .font: UIFont.scdream(.medium, size: 17),
            .foregroundColor: UIColor(Color.mainBlack),
        ]

        let backIndicatorImage = Self.backIndicatorImage()
        if let backIndicatorImage {
            defaultAppearance.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorImage)
        }

        let navigationBar = UINavigationBar.appearance()
        navigationBar.tintColor = UIColor(Color.subBlack)
        navigationBar.backIndicatorImage = backIndicatorImage
        navigationBar.backIndicatorTransitionMaskImage = backIndicatorImage
        navigationBar.standardAppearance = defaultAppearance
        navigationBar.compactAppearance = defaultAppearance
        navigationBar.scrollEdgeAppearance = defaultAppearance
        navigationBar.compactScrollEdgeAppearance = defaultAppearance
    }

    private static func backIndicatorImage() -> UIImage? {
        guard let image = DSKitResource.uiImage(named: "backButton") else { return nil }

        let targetSize = CGSize(width: 18, height: 18)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        .withRenderingMode(.alwaysTemplate)
    }
}
