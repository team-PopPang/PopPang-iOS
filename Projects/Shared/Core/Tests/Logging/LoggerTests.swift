import Testing
@testable import Core

struct LoggerTests {
    @Test
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
