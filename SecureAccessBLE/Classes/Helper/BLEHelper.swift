//
//  BLEHelper.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Writes the textual representations of an object into the standard output.
func debugPrint(_ object: Any) {
    #if DEBUG
        Swift.debugPrint(object)
    #endif
}

/// Logs the message to an external console
func consoleLog(_ message: String) {
    if let logger = BLEHelper.consoleLogger {
        logger.log(message)
    }
}

/**
 *  Helper for BLE framework
 */
public struct BLEHelper {
    /// A dependency injectable ConsoleLogger instance
    public static var consoleLogger: ConsoleLogger?
}

/// Protocol to dependency inject an external console logger
public protocol ConsoleLogger {
    func log(_ message: String)
}
