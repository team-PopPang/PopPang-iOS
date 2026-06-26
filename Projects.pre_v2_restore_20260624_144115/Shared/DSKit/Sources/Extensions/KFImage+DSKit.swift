import Kingfisher
import SwiftUI

public enum ImagePresent {
    case small
    case medium
    case large
    case bestPopupCell
    case comingPopupCell
    case gridPopupCell
    case calendarPopupCell
    case favoriteListCell
    case favoriteCalendarCell
    case alertPopupCell
    case searchGridPopupCell

    public var size: CGSize {
        switch self {
        case .small, .medium, .calendarPopupCell, .favoriteCalendarCell, .alertPopupCell:
            CGSize(width: 106, height: 133)
        case .large, .bestPopupCell:
            CGSize(width: 194, height: 271)
        case .comingPopupCell:
            CGSize(width: 283, height: 138)
        case .gridPopupCell, .favoriteListCell, .searchGridPopupCell:
            CGSize(width: (UIScreen.main.bounds.width - 15 * 3) / 2, height: 217)
        }
    }
}

public extension KFImage {
    func downSampled(_ present: ImagePresent, scale: CGFloat = UIScreen.main.scale) -> some View {
        setProcessor(DownsamplingImageProcessor(size: present.size))
            .scaleFactor(scale)
            .cacheOriginalImage()
            .resizable()
    }
}
