import SwiftUI

public extension View {
    /// 이 뷰 위에 하단 시트를 겹쳐 그린다.
    ///
    /// `detent`가 `nil`이면 시트를 숨긴다. 가장 낮은 단계보다 아래로 끌어 내리면 `detent`가 `nil`이 된다.
    /// 높이 비율은 이 modifier를 붙인 뷰의 높이를 기준으로 계산한다.
    /// 모달이 아니므로 시트 밖의 화면은 계속 만질 수 있다.
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
        overlay {
            BottomSheetContainer(
                detent: detent,
                detents: detents,
                canHide: true,
                content: content()
            )
        }
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
        overlay {
            BottomSheetContainer(
                detent: Binding(
                    get: { item.wrappedValue == nil ? nil : detent.wrappedValue },
                    set: { newValue in
                        // 끌어서 숨길 수 없게 만들었으므로 nil은 들어오지 않는다.
                        if let newValue {
                            detent.wrappedValue = newValue
                        }
                    }
                ),
                detents: detents,
                canHide: false,
                content: item.wrappedValue.map { value in
                    content(value).id(value.id)
                }
            )
        }
    }
}
