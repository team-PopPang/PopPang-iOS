import SheetKit
import SwiftUI

public extension View {
    /// SheetKit 하단 시트에 PopPang 모양(흰 배경, 위쪽 모서리 30)을 입힌다.
    ///
    /// 시트를 붙인 뷰나 그 상위 뷰에 한 번 붙이면 아래의 시트 모두에 적용된다.
    func ppBottomSheetStyle() -> some View {
        bottomSheetBackground(PPColor.background)
            .bottomSheetCornerRadius(PPBottomSheetMetrics.cornerRadius)
    }
}

private enum PPBottomSheetMetrics {
    /// 지도 시트에서 쓰던 모서리 반지름. `PPRadius`에 같은 값이 없어 시트 모양 안에 둔다.
    static let cornerRadius: CGFloat = 30
}
