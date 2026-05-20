import Testing
@testable import Core

struct ExternalLinkConfigTests {
    @Test
    func providesExternalLinksFromLegacyConstants() {
        #expect(
            ExternalLinkConfig.notificationURL.absoluteString
                == "https://deciduous-jam-49e.notion.site/29cdb9e736cf8046babdd84eb78040b3"
        )
        #expect(
            ExternalLinkConfig.serviceTermsURL.absoluteString
                == "https://deciduous-jam-49e.notion.site/2abdb9e736cf80cdaaa0eeeb97313523?pvs=74"
        )
        #expect(
            ExternalLinkConfig.appStoreURL.absoluteString
                == "https://apps.apple.com/kr/app/%ED%8C%9D%ED%8C%A1/id6753014613"
        )
    }

    @Test
    func buildsPopupUniversalLinkFromLegacyBaseURL() {
        let popupUniversalLink = ExternalLinkConfig.popupUniversalLink(popupID: "abcd-1234")

        #expect(popupUniversalLink.absoluteString == "https://poppang.co.kr/popup/abcd-1234")
    }
}
