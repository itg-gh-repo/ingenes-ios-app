// Logger.swift
// TAG2
//
// Unified logging utility with configurable levels

import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

final class Logger {
    static let shared = Logger()

    private let osLog = OSLog(subsystem: AppConfig.bundleId, category: "TAG2")

    #if DEBUG
    var minimumLevel: LogLevel = .debug
    #else
    var minimumLevel: LogLevel = .warning
    #endif

    private init() {}

    // MARK: - Logging Methods

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        guard level >= minimumLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let prefix: String
        let osLogType: OSLogType

        switch level {
        case .debug:
            prefix = "🔍"
            osLogType = .debug
        case .info:
            prefix = "ℹ️"
            osLogType = .info
        case .warning:
            prefix = "⚠️"
            osLogType = .default
        case .error:
            prefix = "❌"
            osLogType = .error
        case .none:
            return
        }

        let logMessage = "\(prefix) [\(fileName):\(line)] \(function) - \(message)"

        #if DEBUG
        // Print to console in debug builds
        print(logMessage)
        #endif

        // Always log to unified logging system
        os_log("%{public}@", log: osLog, type: osLogType, logMessage)
    }
}

// MARK: - Convenience Global Functions

func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}
