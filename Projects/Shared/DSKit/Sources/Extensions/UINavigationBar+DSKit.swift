import SwiftUI
import UIKit

public extension UINavigationBar {
    static func configureAppearance() {
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithOpaqueBackground()
        defaultAppearance.backgroundColor = .clear
        defaultAppearance.shadowColor = .clear

        let backAppearance = UIBarButtonItemAppearance()
        backAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        defaultAppearance.backButtonAppearance = backAppearance

        defaultAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 26),
            .foregroundColor: UIColor.black,
        ]

        if let chevronImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate) {
            let resized = chevronImage.preparingThumbnail(of: CGSize(width: 18, height: 18))
            let tinted = resized?.withTintColor(UIColor(Color.subBlack), renderingMode: .alwaysOriginal)
            let adjusted = tinted?.withAlignmentRectInsets(
                UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 0)
            )

            if let adjusted {
                defaultAppearance.setBackIndicatorImage(adjusted, transitionMaskImage: adjusted)
            }
        }

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = defaultAppearance
        navigationBar.compactAppearance = defaultAppearance
    }
}
