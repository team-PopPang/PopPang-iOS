import Testing
@testable import Core

struct ConstantsTests {
    @Test
    func mirrorsLegacyConstantValues() {
        #expect(Constants.URL.notification == ExternalLinkConfig.notificationURLString)
        #expect(Constants.URL.serviceTerms == ExternalLinkConfig.serviceTermsURLString)
        #expect(Constants.PopPangAPI.apiURL == NetworkConfig.apiURLString)
        #expect(Constants.PopPangAPI.imageURL == NetworkConfig.imageURLString)
    }

    @Test
    func keepsLegacyBetaNoticeContent() {
        #expect(Constants.BetaNotice.beta_1012.contains("홈화면"))
        #expect(Constants.BetaNotice.beta_1012.contains("캘린더화면"))
    }
}
