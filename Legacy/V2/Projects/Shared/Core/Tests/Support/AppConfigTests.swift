import Testing
@testable import Core

struct AppConfigTests {
    @Test("AppConfig가 Info 딕셔너리에서 문자열 값을 읽는다")
    func readsStringValueFromInfoDictionary() {
        let value = AppConfig.string(
            forKey: "KAKAO_NATIVE_APP_KEY",
            in: ["KAKAO_NATIVE_APP_KEY": "sample-key"]
        )

        #expect(value == "sample-key")
    }
}
