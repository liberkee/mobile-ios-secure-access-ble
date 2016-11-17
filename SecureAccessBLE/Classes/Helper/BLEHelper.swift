//
//  BLEHelper.swift
//  BLE
//
//  Created by Ke Song on 03.05.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
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
 To run the function or codes with delay
 
 - parameter delay:   delay time interval
 - parameter closure: functions or codes should be ran after delay
 */
func Delay(_ delay:Double, closure:@escaping ()->()) {
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
        return urls[urls.count-1]
    }
    
}

/// Protocol to dependency inject an external console logger
public protocol ConsoleLogger {
    func log(_ message: String)
}

