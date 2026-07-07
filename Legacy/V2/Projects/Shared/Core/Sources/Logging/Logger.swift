import Foundation

public struct Logger {
    public enum Level: String {
        case debug = "DEBUG"
        case warning = "WARNING"
        case error = "ERROR"
    }

    @discardableResult
    public static func d(
        _ message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) -> String {
        log(.debug, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    public static func w(
        _ message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) -> String {
        log(.warning, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    public static func e(
        _ message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) -> String {
        log(.error, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    public static func log(
        _ level: Level,
        message: String,
        file: String,
        line: Int,
        function: String
    ) -> String {
        let icon: String
        switch level {
        case .debug:
            icon = "🟢"
        case .warning:
            icon = "🟡"
        case .error:
            icon = "🔴"
        }

        let fileName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let logMessage = "[\(icon)] [\(fileName):\(line)] \(function) - \(message)"
        print(logMessage)
        return logMessage
    }
}
