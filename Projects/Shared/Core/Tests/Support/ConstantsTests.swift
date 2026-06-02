import Testing
@testable import Core

struct ConstantsTests {
    @Test("레거시 Constants 값이 Core 설정 값과 일치한다")
    func mirrorsLegacyConstantValues() {
        #expect(Constants.URL.notification == ExternalLinkConfig.notificationURLString)
        #expect(Constants.URL.serviceTerms == ExternalLinkConfig.serviceTermsURLString)
        #expect(Constants.PopPangAPI.apiURL == NetworkConfig.apiURLString)
        #expect(Constants.PopPangAPI.imageURL == NetworkConfig.imageURLString)
    }

    @Test("레거시 베타 공지 문구를 유지한다")
    func keepsLegacyBetaNoticeContent() {
        #expect(Constants.BetaNotice.beta_1012.contains("홈화면"))
        #expect(Constants.BetaNotice.beta_1012.contains("캘린더화면"))
    }
}
