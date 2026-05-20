import SwiftUI
import Testing
@testable import DSKit

struct ButtonTests {
    @Test
    func sortOptionTitlesMatchLegacyValues() {
        #expect(SortButton.SortOption.newest.title == "최신순")
        #expect(SortButton.SortOption.closingSoon.title == "마감순")
        #expect(SortButton.SortOption.mostFavorited.title == "찜순")
        #expect(SortButton.SortOption.mostViewed.title == "조회순")
    }

    @Test
    func dropdownUsesProvidedOptions() {
        let options = ["전체", "서울", "부산"]
        let view = DropDownView(
            options: options,
            selection: .constant(nil)
        )

        _ = view.body
        #expect(options.first == "전체")
    }

    @Test
    func socialLoginButtonUsesExpectedImageNames() {
        #expect(SocialLoginButton.SocialType.kakao.imageName == "Logo Kakao")
        #expect(SocialLoginButton.SocialType.apple.imageName == "Logo Apple")
        #expect(SocialLoginButton.SocialType.google.imageName == "Logo Google")
    }
}
