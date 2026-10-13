import CoreGraphics

/// 하단 시트가 멈출 수 있는 높이 단계.
///
/// SwiftUI의 `PresentationDetent`처럼 enum이 아니라 struct로 둔다.
/// 쓰는 쪽은 값을 넘기기만 하므로, 나중에 높이 종류를 더해도 쓰는 쪽 코드가 깨지지 않는다.
public struct BottomSheetDetent: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case fraction(CGFloat)
        case height(CGFloat)
        case large
    }

    let kind: Kind

    /// 시트를 붙인 뷰 높이의 절반.
    public static let medium = BottomSheetDetent(kind: .fraction(0.5))

    /// 올릴 수 있는 끝. 시트를 붙인 뷰 높이에서 `bottomSheetTopInset(_:)`만큼 뺀 높이다.
    public static let large = BottomSheetDetent(kind: .large)

    /// 시트를 붙인 뷰 높이에 대한 비율. 0부터 1 사이 값을 쓴다.
    public static func fraction(_ value: CGFloat) -> BottomSheetDetent {
        BottomSheetDetent(kind: .fraction(value))
    }

    /// 고정 높이(pt).
    public static func height(_ value: CGFloat) -> BottomSheetDetent {
        BottomSheetDetent(kind: .height(value))
    }
}
