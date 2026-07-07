import Testing
@testable import Core

struct LoggerTests {
    @Test("Logger가 파일명과 함수 문맥을 포함한 메시지를 만든다")
    func loggerFormatsMessageWithFileAndFunctionContext() {
        let message = Logger.log(
            .debug,
            message: "hello",
            file: "/tmp/SampleFile.swift",
            line: 42,
            function: "testFunction()"
        )

        #expect(message == "[🟢] [SampleFile:42] testFunction() - hello")
    }
}
