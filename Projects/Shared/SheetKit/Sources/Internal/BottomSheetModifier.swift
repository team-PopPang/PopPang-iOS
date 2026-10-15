import SwiftUI

/// 시트를 겹쳐 그리고, 이 시트를 끄는 거리를 먼저 붙인 시트들에 알려 준다.
struct BottomSheetModifier<Sheet: View>: ViewModifier {
    let sheet: (BottomSheetLink) -> Sheet

    /// 이 시트 위에 겹친 시트(나중에 붙인 시트)들의 연결.
    @Environment(\.bottomSheetLinksAbove) private var linksAbove
    @State private var link = BottomSheetLink()

    func body(content: Content) -> some View {
        content
            // 먼저 붙인 시트들은 이 시트 아래에 그려진다.
            // 이 시트와 그 위의 시트들을 끌 때 같이 움직이도록, 받은 연결 목록에 이 시트의 연결을 더해 넘긴다.
            .environment(\.bottomSheetLinksAbove, linksAbove + [link])
            .overlay {
                sheet(link)
            }
    }
}

// 아래 두 뷰는 보일지와 높이를 자기 `@Binding`으로 body에서 읽는다.
// `bottomSheet(...)` 안에서 값을 미리 읽어 넘기면, 상위 뷰 구조(지도 화면의 `GeometryReader`)에 따라
// 상태가 바뀌어도 시트가 다시 그려지지 않아 두 번째 시트가 열리지 않았다.

/// `bottomSheet(detent:)`: 높이 단계가 `nil`이면 숨긴다.
struct DetentBottomSheet<Content: View>: View {
    @Binding var detent: BottomSheetDetent?
    let detents: Set<BottomSheetDetent>
    let link: BottomSheetLink
    let content: () -> Content

    var body: some View {
        BottomSheetContainer(
            detent: detent,
            detents: detents,
            canHide: true,
            link: link,
            setDetent: { detent = $0 },
            content: content()
        )
    }
}

/// `bottomSheet(item:detent:)`: `item`이 `nil`이면 숨기고, 끌어서는 숨기지 않는다.
struct ItemBottomSheet<Item: Identifiable, Content: View>: View {
    @Binding var item: Item?
    @Binding var detent: BottomSheetDetent
    let detents: Set<BottomSheetDetent>
    let link: BottomSheetLink
    let content: (Item) -> Content

    var body: some View {
        BottomSheetContainer(
            detent: item == nil ? nil : detent,
            detents: detents,
            canHide: false,
            link: link,
            setDetent: { newValue in
                // 끌어서 숨길 수 없으므로 nil은 들어오지 않는다.
                if let newValue {
                    detent = newValue
                }
            },
            content: item.map { value in
                content(value).id(value.id)
            }
        )
    }
}
