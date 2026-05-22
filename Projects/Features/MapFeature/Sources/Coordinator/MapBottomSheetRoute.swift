import Core
import Foundation

public enum MapBottomSheetRoute: String, BottomSheetPresentingRoute {
    case popupList
    case popupDetail

    public var id: String {
        rawValue
    }

    public var preferredDetent: BottomSheetDetent {
        switch self {
        case .popupList:
            .fraction(0.4)
        case .popupDetail:
            .fraction(0.6)
        }
    }

    public var supportedDetents: [BottomSheetDetent] {
        switch self {
        case .popupList:
            [.fraction(0.25), .fraction(0.4), .fraction(0.7)]
        case .popupDetail:
            [.fraction(0.4), .fraction(0.6), .fraction(0.85)]
        }
    }
}
