import SwiftUI

public extension View {
    /// 시트를 끝까지 올렸을 때(`.large`) 시트 위에 남길 공간.
    ///
    /// 시트를 붙인 뷰의 위쪽 끝에서 잰 값이다. 이 뷰나 상위 뷰에 붙이면 아래의 시트 모두에 적용된다.
    func bottomSheetTopInset(_ inset: CGFloat) -> some View {
        environment(\.bottomSheetTopInset, inset)
    }

    /// 시트 배경. 이 뷰나 상위 뷰에 붙이면 아래의 시트 모두에 적용된다.
    func bottomSheetBackground<S: ShapeStyle>(_ style: S) -> some View {
        environment(\.bottomSheetBackground, AnyShapeStyle(style))
    }

    /// 시트 위쪽 모서리의 반지름. 이 뷰나 상위 뷰에 붙이면 아래의 시트 모두에 적용된다.
    func bottomSheetCornerRadius(_ radius: CGFloat) -> some View {
        environment(\.bottomSheetCornerRadius, radius)
    }
}
