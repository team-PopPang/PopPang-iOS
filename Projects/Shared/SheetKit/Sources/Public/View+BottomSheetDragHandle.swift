import SwiftUI

public extension View {
    /// 이 뷰를 끌어도 시트가 움직이게 한다.
    ///
    /// 시트 안의 제목 줄처럼 목록이 아닌 곳에 붙인다. 이 뷰에서 시작한 세로 끌기는 손잡이 줄처럼 시트를 움직인다.
    /// 안쪽 버튼은 탭을 그대로 받는다. 버튼 위에서 시작해 끌면 버튼은 눌리지 않고 시트가 움직인다.
    ///
    /// 스크롤뷰나 `List` 안의 뷰에는 붙이지 않는다. 스크롤과 끌기가 경쟁한다.
    /// 목록 위에서 시작한 끌기는 목록만 스크롤하도록, 목록은 이 수정자 밖에 둔다.
    /// 시트 밖에서는 아무 일도 하지 않는다.
    ///
    /// ```swift
    /// .bottomSheet(detent: $detent) {
    ///     VStack(spacing: 0) {
    ///         SheetHeader()
    ///             .bottomSheetDragHandle()
    ///         PlaceList()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter isEnabled: `false`면 끌기 손잡이로 쓰지 않는다.
    ///   수정자를 `if`로 붙였다 떼면 뷰의 상태가 초기화되므로 이 값으로 끈다.
    func bottomSheetDragHandle(_ isEnabled: Bool = true) -> some View {
        modifier(BottomSheetDragHandleModifier(isEnabled: isEnabled))
    }
}
