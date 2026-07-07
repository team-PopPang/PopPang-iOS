import UIKit

public extension UIApplication {
    func endEditing(_ force: Bool) {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .endEditing(force)
    }
}
