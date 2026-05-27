import Core
import Foundation

public enum MapBottomSheetRoute: String, BottomSheetPresentingRoute {
    case popupList
    case popupDetailSheet

    public var id: String {
        rawValue
    }

    public var preferredDetent: BottomSheetDetent {
        switch self {
        case .popupList:
            .fraction(0.4)
        case .popupDetailSheet:
            .fraction(0.6)
        }
    }

    public var supportedDetents: [BottomSheetDetent] {
        switch self {
        case .popupList:
            [.fraction(0.25), .fraction(0.4), .fraction(0.7)]
        case .popupDetailSheet:
            [.fraction(0.4), .fraction(0.6), .fraction(0.85)]
        }
    }
}
