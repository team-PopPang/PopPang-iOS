import CoreGraphics
import Foundation

/// 시트를 끄는 제스처가 붙은 곳.
///
/// 목록(스크롤뷰, `List`)에는 시트 제스처를 붙이지 않는다. 목록 위에서 시작한 끌기는 언제나 목록만 스크롤한다.
enum BottomSheetDragSource: Hashable {
    /// 시트 위쪽의 손잡이 줄.
    case grabber
    /// 내용이 터치를 받지 않는 시트 배경(여백, `Spacer`).
    case background
    /// `bottomSheetDragHandle(_:)`로 지정한 뷰. 뷰마다 다른 값이다.
    case handle(UUID)
}

/// 시트를 움직이고 있는 끌기.
///
/// 한 번에 하나만 시트를 움직인다. 먼저 시작한 끌기를 끝까지 따르고, 그동안 다른 곳에서 온 끌기(다른 손가락)는 무시한다.
struct BottomSheetDrag: Equatable {
    /// 끌기를 시작한 곳.
    let source: BottomSheetDragSource
    /// 가로로 시작한 끌기인지. 가로 끌기는 시트를 움직이지 않는다.
    let isHorizontal: Bool

    /// 제스처에서 온 끌기 알림을 다루는 방법.
    enum Decision: Equatable {
        /// 진행 중인 끌기가 없어 새로 시작한다.
        case begin
        /// 이 곳에서 시작한 끌기를 이어 간다.
        case follow
        /// 다른 곳에서 시작한 끌기가 시트를 움직이는 중이라 무시한다.
        case ignore
    }

    /// 이 곳에서 온 끌기 알림을 어떻게 다룰지 정한다.
    static func decision(for source: BottomSheetDragSource, current: BottomSheetDrag?) -> Decision {
        guard let current else { return .begin }
        return current.source == source ? .follow : .ignore
    }

    /// 끌기를 시작할 때 움직인 방향이 가로인지. 세로로 움직인 거리보다 가로로 움직인 거리가 길면 가로다.
    static func isHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }
}
