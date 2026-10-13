import Observation
import SwiftUI

/// 같은 뷰에 겹쳐 붙인 시트들이 끄는 거리를 나누는 연결.
///
/// 시트마다 하나씩 두고, 그 시트보다 먼저 붙인 시트(아래에 그려지는 시트)가 environment로 읽는다.
/// 위 시트를 끄는 동안 아래 시트도 같은 거리만큼 같이 움직여서, 손을 뗀 뒤에야 따라가는 잔상이 생기지 않는다.
@Observable
final class BottomSheetLink {
    /// 이 시트를 끄는 동안 움직인 거리.
    var ownTranslation: CGFloat = 0

    /// 이 시트 위에 겹친 시트의 연결. 그 시트를 끌 때도 아래 시트까지 같이 움직이도록 이어 준다.
    @ObservationIgnored weak var linkAbove: BottomSheetLink?

    /// 이 시트와 그 위에 겹친 시트들을 끄는 거리의 합. 아래 시트는 이 거리만큼 같이 움직인다.
    var translation: CGFloat {
        ownTranslation + (linkAbove?.translation ?? 0)
    }
}
