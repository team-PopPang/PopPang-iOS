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
    /// 높이와 최대 높이가 모두 0.01pt 이하로만 바뀌면(부동소수점 계산 오차) 부르지 않는다. 받은 높이로 다시 레이아웃이
    /// 바뀌어 소수점 끝자리만큼 흔들리는 값이 되돌아와도 끝없이 불리지 않게 하기 위해서다.
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
        modifier(BottomSheetGeometryChangeModifier(action: action))
    }
}

/// 시트 높이가 계산 오차보다 크게 바뀌었을 때만 알린다.
private struct BottomSheetGeometryChangeModifier: ViewModifier {
    let action: (BottomSheetGeometry) -> Void
    /// 마지막으로 알린 높이. 화면을 다시 그리지 않도록 값이 바뀌어도 body를 다시 부르지 않는 상자에 둔다.
    @State private var lastDelivered = LastDeliveredGeometry()

    func body(content: Content) -> some View {
        content.onPreferenceChange(BottomSheetGeometryKey.self) { geometry in
            guard let geometry else {
                // 시트를 붙인 뷰가 사라졌다. 다시 나타나면 처음 높이부터 알린다.
                lastDelivered.value = nil
                return
            }
            guard geometry.isMeaningfullyDifferent(from: lastDelivered.value) else { return }
            lastDelivered.value = geometry
            action(geometry)
        }
    }
}

private final class LastDeliveredGeometry {
    var value: BottomSheetGeometry?
}

extension BottomSheetGeometry {
    /// 높이나 최대 높이가 계산 오차보다 크게 다른지. 비교할 값이 없으면 다르다고 본다.
    func isMeaningfullyDifferent(from other: BottomSheetGeometry?) -> Bool {
        guard let other else { return true }
        return BottomSheetMetrics.isMeaningfulChange(from: other.height, to: height)
            || BottomSheetMetrics.isMeaningfulChange(from: other.maxHeight, to: maxHeight)
    }
}
