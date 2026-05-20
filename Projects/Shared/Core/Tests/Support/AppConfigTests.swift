import Testing
@testable import Core

struct AppConfigTests {
    @Test
    func readsStringValueFromInfoDictionary() {
        let value = AppConfig.string(
            forKey: "KAKAO_NATIVE_APP_KEY",
            in: ["KAKAO_NATIVE_APP_KEY": "sample-key"]
        )

        #expect(value == "sample-key")
    }
}
