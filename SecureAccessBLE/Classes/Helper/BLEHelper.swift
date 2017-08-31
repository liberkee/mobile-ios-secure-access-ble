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
 To run the function or codes with delay

 - parameter delay:   delay time interval
 - parameter closure: functions or codes should be ran after delay
 */
func Delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

/**
 *  Helper for BLE framework
 */
public struct BLEHelper {
    /// A dependency injectable ConsoleLogger instance
    public static var consoleLogger: ConsoleLogger?

    /// The applications documents directory path
    static var applicationDocumentsDirectory: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }
}

/// Protocol to dependency inject an external console logger
public protocol ConsoleLogger {
    func log(_ message: String)
}
