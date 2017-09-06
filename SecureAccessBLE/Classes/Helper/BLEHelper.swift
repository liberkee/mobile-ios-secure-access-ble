//
//  BLEHelper.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

extension Data {

    /// Converts the data to a UUID string in lowercased format with hyphens if possible. Otherwise it returns nil.
    var uuidString: String? {

        guard count == 16 else { return nil }

        // taken from: https://gist.github.com/DonaldHays/e5dc53c89e5abfe866f0

        var output = ""

        for (index, byte) in enumerated() {
            let nextCharacter = String(byte, radix: 16)
            if nextCharacter.characters.count == 2 {
                output += nextCharacter
            } else {
                output += "0" + nextCharacter
            }

            if [3, 5, 7, 9].index(of: index) != nil {
                output += "-"
            }
        }

        return output
    }
}

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
