import SwiftUI

public extension View {
    /// 이 뷰 위에 하단 시트를 겹쳐 그린다.
    ///
    /// `detent`가 `nil`이면 시트를 숨긴다. 가장 낮은 단계보다 아래로 끌어 내리면 `detent`가 `nil`이 된다.
    /// 높이 비율은 이 modifier를 붙인 뷰의 높이를 기준으로 계산한다.
    /// 모달이 아니므로 시트 밖의 화면은 계속 만질 수 있다.
    ///
    /// 손잡이 줄, 내용이 터치를 받지 않는 빈 곳, `bottomSheetDragHandle(_:)`을 붙인 뷰를 끌면 높이가 바뀐다.
    /// 목록(스크롤뷰, `List`) 위에서 시작한 끌기는 목록만 스크롤한다.
    ///
    /// 같은 뷰에 시트를 여러 장 붙이면 나중에 붙인 시트가 위에 그려진다.
    /// 위 시트를 끄는 동안 아래 시트도 같은 거리만큼 같이 움직인다.
    ///
    /// 시트 위에 띄울 버튼처럼 시트 높이에 맞춰 움직일 뷰는 `onBottomSheetGeometryChange(_:)`로 높이를 받아 옮긴다.
    ///
    /// ```swift
    /// @State private var detent: BottomSheetDetent? = .medium
    ///
    /// Map()
    ///     .bottomSheet(detent: $detent) {
    ///         PlaceList()
    ///     }
    /// ```
    func bottomSheet<Content: View>(
        detent: Binding<BottomSheetDetent?>,
        detents: Set<BottomSheetDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            BottomSheetModifier { link in
                DetentBottomSheet(
                    detent: detent,
                    detents: detents,
                    link: link,
                    content: content
                )
            }
        )
    }

    /// `item`이 있을 때만 이 뷰 위에 하단 시트를 겹쳐 그린다.
    ///
    /// 시스템 `.sheet(item:)`처럼 `item`이 `nil`이 되면 시트를 숨긴다.
    /// 높이 바인딩이 Optional이 아니므로 끌어서는 닫히지 않고 높이만 바뀐다.
    /// 시트가 열린 채로 `item`이 바뀌면 높이는 그대로 두고 내용만 새로 만든다.
    func bottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        detent: Binding<BottomSheetDetent>,
        detents: Set<BottomSheetDetent> = [.medium, .large],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(
            BottomSheetModifier { link in
                ItemBottomSheet(
                    item: item,
                    detent: detent,
                    detents: detents,
                    link: link,
                    content: content
                )
            }
        )
    }
}
