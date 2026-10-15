import CoreGraphics

extension BottomSheetDetent {
    /// 높이를 계산하는 방식. 쓰는 쪽은 `.medium`, `.fraction(_:)` 같은 공개 값으로만 만든다.
    enum Kind: Hashable, Sendable {
        case fraction(CGFloat)
        case height(CGFloat)
        case large
    }
}
