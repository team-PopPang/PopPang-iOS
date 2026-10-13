import Observation
import SwiftUI

/// 같은 뷰에 겹쳐 붙인 시트가 끄는 거리를 아래 시트에 알리는 연결.
///
/// 시트마다 하나씩 두고, 그 시트보다 먼저 붙인 시트(아래에 그려지는 시트)들에 environment로 넘긴다.
/// 아래 시트는 위에 겹친 시트들이 끄는 거리를 모두 더해 같이 움직이므로, 손을 뗀 뒤에야 따라가는 잔상이 생기지 않는다.
@Observable
final class BottomSheetLink {
    /// 이 시트를 끄는 동안 움직인 거리.
    var translation: CGFloat = 0
}

extension Array where Element == BottomSheetLink {
    /// 위에 겹친 시트들을 끄는 거리의 합. 아래 시트는 이 거리만큼 같이 움직인다.
    var totalTranslation: CGFloat {
        reduce(0) { $0 + $1.translation }
    }
}

private struct BottomSheetLinksAboveKey: EnvironmentKey {
    static var defaultValue: [BottomSheetLink] { [] }
}

extension EnvironmentValues {
    /// 이 시트 위에 겹친 시트(나중에 붙인 시트)들의 연결.
    /// 시트마다 받은 목록에 자기 연결을 더해 먼저 붙인 시트들에 넘기므로, 시트를 그리는 순서와 관계없이 맨 아래 시트까지 전달된다.
    var bottomSheetLinksAbove: [BottomSheetLink] {
        get { self[BottomSheetLinksAboveKey.self] }
        set { self[BottomSheetLinksAboveKey.self] = newValue }
    }
}
