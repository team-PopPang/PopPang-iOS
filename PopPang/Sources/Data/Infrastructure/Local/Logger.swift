//
//  Logger.swift
//  PopPang
//
//  Created by 김동현 on 11/5/25.
//

import Foundation

struct Logger {
    enum LogType: String {
        case debug = "DEBUG"
        case warning = "WARNING"
        case error = "ERROR"
    }

    @discardableResult
    static func d(_ message: String,
                  file: String = #file,
                  line: Int = #line,
                  function: String = #function) -> String {
        return log(type: .debug, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    static func w(_ message: String,
                  file: String = #file,
                  line: Int = #line,
                  function: String = #function) -> String {
        return log(type: .warning, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    static func e(_ message: String,
                  file: String = #file,
                  line: Int = #line,
                  function: String = #function) -> String {
        return log(type: .error, message: message, file: file, line: line, function: function)
    }

    @discardableResult
    private static func log(type: LogType,
                            message: String,
                            file: String,
                            line: Int,
                            function: String) -> String {
        let icon: String
        switch type {
        case .debug: icon = "🟢"
        case .warning: icon = "🟡"
        case .error: icon = "🔴"
        }

        let fileName = (file as NSString).lastPathComponent
        // let logMessage = "\(icon) [\(fileName) -> \(line) -> \(function)] \(message)"
        let logMessage = "[\(icon)] [\(fileName):\(line)] \(function) — \(message)"

        print(logMessage)
        return logMessage
    }
}
