import SwiftUI

private struct BottomSheetTopInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct BottomSheetBackgroundKey: EnvironmentKey {
    static var defaultValue: AnyShapeStyle { AnyShapeStyle(.background) }
}

private struct BottomSheetCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 16
}

extension EnvironmentValues {
    var bottomSheetTopInset: CGFloat {
        get { self[BottomSheetTopInsetKey.self] }
        set { self[BottomSheetTopInsetKey.self] = newValue }
    }

    var bottomSheetBackground: AnyShapeStyle {
        get { self[BottomSheetBackgroundKey.self] }
        set { self[BottomSheetBackgroundKey.self] = newValue }
    }

    var bottomSheetCornerRadius: CGFloat {
        get { self[BottomSheetCornerRadiusKey.self] }
        set { self[BottomSheetCornerRadiusKey.self] = newValue }
    }
}
