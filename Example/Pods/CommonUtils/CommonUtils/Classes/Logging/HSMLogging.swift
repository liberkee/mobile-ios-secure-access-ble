//
//  HSMLogging.swift
//  CommonUtils
//
//  Created by Stefan Lahme on 15.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/// Implement this protocol to create your custom loggers
public protocol HSMLogging {
    func log(message: @autoclosure () -> String, file: String, function: StaticString, line: UInt, level: LogLevel)
}

/// Interface extension, necessary for using default values in function declarations
public extension HSMLogging {
    func log(message: @autoclosure () -> String, file: String = #file, function: StaticString = #function, line: UInt = #line,
             level: LogLevel) {
        HSMLog(message: message, file: file, function: function, line: line, level: level)
    }
}

/// The main function which should be used for logging
public func HSMLog(message: @autoclosure () -> String, file: String = #file, function: StaticString = #function,
                   line: UInt = #line, level: LogLevel) {
    #if DEBUG
        guard level.rawValue <= LoggingManager.shared.logLevel.rawValue else { return }
        LoggingManager.shared.logger.log(message: message, file: file, function: function, line: line, level: level)
    #endif
}
