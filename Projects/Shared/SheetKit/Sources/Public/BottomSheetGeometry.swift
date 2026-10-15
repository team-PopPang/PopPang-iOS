import SwiftUI

/// 시트가 화면을 가린 정도. `onBottomSheetGeometryChange(_:)`로 받는다.
public struct BottomSheetGeometry: Equatable, Sendable {
    /// 시트 높이. 시트를 붙인 뷰의 바닥에서 시트 위쪽 끝까지 잰다. 시트가 숨으면 0이다.
    public var height: CGFloat
    /// 시트를 끝까지 올렸을 때(`.large`)의 높이.
    public var maxHeight: CGFloat

    public init(height: CGFloat, maxHeight: CGFloat) {
        self.height = height
        self.maxHeight = maxHeight
    }
}

public extension View {
    /// 이 뷰에 붙인 시트의 높이가 바뀔 때마다 부른다.
    ///
    /// 끄는 동안과 높이 단계를 옮기는 애니메이션 동안에도 프레임마다 불린다.
    /// 시트 위에 띄울 버튼을 이 높이만큼 올려 그리면 시트와 같은 프레임에 움직이고,
    /// 시트를 숨기면 높이가 0이 되어 버튼도 바닥으로 내려간다.
    /// 시트를 여러 장 겹치면 가장 높이 올라온 시트의 높이를 넘긴다.
    ///
    /// `bottomSheet(...)`를 붙인 뒤에 붙인다. 프레임마다 불리므로 받은 값을 화면의 `@State`에 담지 않는다.
    /// 화면 전체가 프레임마다 다시 그려지지 않도록, 작은 `@Observable` 객체에 담아 그 값을 읽는 뷰만 다시 그린다.
    ///
    /// ```swift
    /// @Observable final class SheetPosition {
    ///     var geometry: BottomSheetGeometry?
    /// }
    ///
    /// @State private var sheetPosition = SheetPosition()
    ///
    /// Map()
    ///     .overlay(alignment: .bottomTrailing) {
    ///         // geometry.height만큼 올려 그리는 작은 뷰. 이 뷰만 다시 그려진다.
    ///         LocationButtonLayer(position: sheetPosition)
    ///     }
    ///     .bottomSheet(detent: $detent) {
    ///         PlaceList()
    ///     }
    ///     .onBottomSheetGeometryChange { geometry in
    ///         sheetPosition.geometry = geometry
    ///     }
    /// ```
    func onBottomSheetGeometryChange(_ action: @escaping (BottomSheetGeometry) -> Void) -> some View {
        onPreferenceChange(BottomSheetGeometryKey.self) { geometry in
            guard let geometry else { return }
            action(geometry)
        }
    }
}
