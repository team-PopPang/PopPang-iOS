import SwiftUI

/// 시트 높이를 프레임마다 preference로 올려 보낸다.
///
/// `Animatable`이라 높이 단계를 옮기는 애니메이션 동안에도 SwiftUI가 중간 높이로 `body`를 다시 부른다.
/// 도착 높이만 알리면 받는 쪽 버튼이 애니메이션 없이 도착점으로 튄다.
struct BottomSheetGeometryReporter: ViewModifier, Animatable {
    var height: CGFloat
    let maxHeight: CGFloat
    /// `false`면 알리지 않는다. 시트를 붙인 뷰의 높이를 재기 전의 값을 바깥에 흘리지 않기 위해서다.
    let isActive: Bool

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content.preference(
            key: BottomSheetGeometryKey.self,
            value: isActive ? BottomSheetGeometry(height: height, maxHeight: maxHeight) : nil
        )
    }
}

/// 시트들이 올려 보낸 높이. 시트를 여러 장 겹치면 가장 높이 올라온 시트를 남긴다.
struct BottomSheetGeometryKey: PreferenceKey {
    static var defaultValue: BottomSheetGeometry? { nil }

    static func reduce(value: inout BottomSheetGeometry?, nextValue: () -> BottomSheetGeometry?) {
        value = BottomSheetGeometry.higher(value, nextValue())
    }
}

extension BottomSheetGeometry {
    /// 두 시트 가운데 더 높이 올라온 시트. 한쪽만 있으면 그쪽을 쓴다.
    static func higher(_ lhs: BottomSheetGeometry?, _ rhs: BottomSheetGeometry?) -> BottomSheetGeometry? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs.height >= rhs.height ? lhs : rhs
    }
}
