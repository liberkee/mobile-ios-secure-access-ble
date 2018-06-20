//
//  LoggingManager.swift
//  CommonUtils
//
//  Created on 15.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Set the used logger, log level and time stamp formatter here
class LoggingManager {
    /// Used logger, either custom or default
    var logger: HSMLogging

    /// Used log level for filtering log statements
    var logLevel: LogLevel

    /// Log time stamp formatter
    lazy var dateFormatter: DateFormatter = {
        let dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localeIdentifier = "DE_de"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = dateFormat
        return formatter
    }()

    /// Shared singleton property
    static let shared = LoggingManager()

    private init(logger: HSMLogging = DefaultLogger(), logLevel: LogLevel = .verbose) {
        self.logger = logger
        self.logLevel = logLevel
    }

    func log(message: @autoclosure () -> String, file: String = #file, function: StaticString = #function, line: UInt = #line,
             level: LogLevel) {
        logger.log(message: message, file: file, function: function, line: line, level: level)
    }
}
