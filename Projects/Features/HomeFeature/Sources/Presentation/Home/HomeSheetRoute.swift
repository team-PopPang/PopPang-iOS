import Foundation

enum HomeSheetRoute: Identifiable, Hashable, Sendable {
    case regionSheet
    case sortSheet

    var id: String {
        switch self {
        case .regionSheet:
            "regionSheet"
        case .sortSheet:
            "sortSheet"
        }
    }
}
