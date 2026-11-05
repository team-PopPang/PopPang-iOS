import SwiftUI

public extension View {
    /// SwiftUI 기본 시트(`.sheet`)의 배경을 PopPang 흰 배경으로 고정한다.
    ///
    /// iOS 26부터 기본 시트 배경이 리퀴드 글래스로 그려진다. 앱의 `UIDesignRequiresCompatibility`는 iOS 27 SDK로 빌드하면 효과가 없어,
    /// 시트 안 내용에 이 modifier를 붙여 배경을 직접 정한다. `.presentationDetents`처럼 시트 내용 쪽에 붙인다.
    func ppSystemSheetStyle() -> some View {
        presentationBackground(PPColor.background)
    }
}
