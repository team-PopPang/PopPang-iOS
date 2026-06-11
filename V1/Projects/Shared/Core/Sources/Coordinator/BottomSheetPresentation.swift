import CoreGraphics
import Foundation

public enum BottomSheetDetent: Hashable, Sendable {
    case hidden
    case fraction(CGFloat)
    case absolute(CGFloat)
}

public protocol BottomSheetPresentingRoute: Identifiable, Sendable {
    var preferredDetent: BottomSheetDetent { get }
    var supportedDetents: [BottomSheetDetent] { get }
}
