import SwiftUI
import UIKit

public enum PresentationAnimation {
    @MainActor
    public static func perform(animated: Bool, _ update: () -> Void) {
        guard animated == false else {
            update()
            return
        }

        let previousAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            update()
        }

        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(previousAnimationsEnabled)
        }
    }
}
