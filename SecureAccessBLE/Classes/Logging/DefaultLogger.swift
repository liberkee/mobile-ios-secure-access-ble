//
//  DefaultLogger.swift
//  CommonUtils
//
//  Created on 15.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// The default logger that forwards all log statements to the debugPrint function
class DefaultLogger: HSMLogging {
    let systemClock: SystemClockType

    init(systemClock: SystemClockType = SystemClock()) {
        self.systemClock = systemClock
    }

    func log(message: @autoclosure () -> String, file: String = #file, function: StaticString = #function, line: UInt = #line,
             level: LogLevel) {
        let formatter = LoggingManager.shared.dateFormatter
        let date = formatter.string(from: systemClock.now())
        let truncatedFileName = file.components(separatedBy: "/").last ?? ""
        logPrint(logStatement: "\(date) [\(truncatedFileName):\(function):\(line)] \(level.toString()): \(message())")
    }

    func logPrint(logStatement: String) {
        debugPrint(logStatement)
    }
}
