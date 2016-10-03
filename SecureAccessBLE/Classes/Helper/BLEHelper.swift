//
//  BLEHelper.swift
//  BLE
//
//  Created by Ke Song on 03.05.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation

/// Logs the message to an external console
func consoleLog(message: String) {
    if let logger = BLEHelper.consoleLogger {
        logger.log(message)
    }
}

/**
 To run the function or codes with delay
 
 - parameter delay:   delay time interval
 - parameter closure: functions or codes should be ran after delay
 */
func Delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

/**
 *  Helper for BLE framework
 */
public struct BLEHelper {
    /// A dependency injectable ConsoleLogger instance
    public static var consoleLogger: ConsoleLogger?
    
    /// The applications documents directory path
    static var applicationDocumentsDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }
    
    /// The frameworks bundle identifier
    static var frameworkBundle: NSBundle {
        return NSBundle(identifier: "de.huf.sm.BLE")!
    }
}

/// Protocol to dependency inject an external console logger
public protocol ConsoleLogger {
    func log(message: String)
}

