//
//  LogLevel.swift
//  CommonUtils
//
//  Created on 15.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Supported log levels
public enum LogLevel: Int {
    case error, warning, info, debug, verbose

    /// Get a description string for the current log level
    public func toString() -> String {
        switch self {
        case .error:
            return "Error"
        case .warning:
            return "Warning"
        case .info:
            return "Info"
        case .debug:
            return "Debug"
        case .verbose:
            return "Verbose"
        }
    }
}
