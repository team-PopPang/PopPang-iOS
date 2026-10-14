import SwiftUI

public extension View {
    /// 이 뷰 위에 하단 시트를 겹쳐 그린다.
    ///
    /// `detent`가 `nil`이면 시트를 숨긴다. 가장 낮은 단계보다 아래로 끌어 내리면 `detent`가 `nil`이 된다.
    /// 높이 비율은 이 modifier를 붙인 뷰의 높이를 기준으로 계산한다.
    /// 모달이 아니므로 시트 밖의 화면은 계속 만질 수 있다.
    ///
    /// 같은 뷰에 시트를 여러 장 붙이면 나중에 붙인 시트가 위에 그려진다.
    /// 위 시트를 끄는 동안 아래 시트도 같은 거리만큼 같이 움직인다.
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
        bottomSheet(detent: detent, detents: detents, content: content) {
            EmptyView()
        }
    }

    /// 하단 시트와 함께, 시트 위쪽 끝에 붙어 시트와 같이 움직이는 뷰(`accessory`)를 그린다.
    ///
    /// 지도의 내 위치 버튼처럼 시트 바로 위에 띄울 뷰를 넘긴다. 끄는 동안에도 시트와 같은 프레임에 움직인다.
    /// 시트를 가장 높은 단계로 올리면 숨고, 바로 아래 단계에서 가장 높은 단계로 가는 동안 점점 흐려진다.
    /// 시트를 숨기면 같이 숨으므로, 그때 보일 뷰는 쓰는 쪽에서 따로 둔다.
    /// 가로 위치와 시트와의 간격은 `accessory` 쪽에서 정한다.
    ///
    /// ```swift
    /// Map()
    ///     .bottomSheet(detent: $detent) {
    ///         PlaceList()
    ///     } accessory: {
    ///         LocationButton()
    ///             .frame(maxWidth: .infinity, alignment: .trailing)
    ///             .padding([.trailing, .bottom], 12)
    ///     }
    /// ```
    func bottomSheet<Content: View, Accessory: View>(
        detent: Binding<BottomSheetDetent?>,
        detents: Set<BottomSheetDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) -> some View {
        modifier(
            BottomSheetModifier { link in
                DetentBottomSheet(
                    detent: detent,
                    detents: detents,
                    link: link,
                    content: content,
                    accessory: accessory
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

/// 시트를 겹쳐 그리고, 이 시트를 끄는 거리를 먼저 붙인 시트들에 알려 준다.
private struct BottomSheetModifier<Sheet: View>: ViewModifier {
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
private struct DetentBottomSheet<Content: View, Accessory: View>: View {
    @Binding var detent: BottomSheetDetent?
    let detents: Set<BottomSheetDetent>
    let link: BottomSheetLink
    let content: () -> Content
    let accessory: () -> Accessory

    var body: some View {
        BottomSheetContainer(
            detent: detent,
            detents: detents,
            canHide: true,
            link: link,
            setDetent: { detent = $0 },
            content: content(),
            accessory: accessory()
        )
    }
}

/// `bottomSheet(item:detent:)`: `item`이 `nil`이면 숨기고, 끌어서는 숨기지 않는다.
private struct ItemBottomSheet<Item: Identifiable, Content: View>: View {
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
            },
            accessory: EmptyView()
        )
    }
}
