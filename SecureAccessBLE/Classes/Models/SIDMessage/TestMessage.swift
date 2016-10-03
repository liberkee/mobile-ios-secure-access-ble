//
//  TestMessage.swift
//  HSM
//
//  Created by Sebastian Stüssel on 19.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation
import UIKit

/**
 The test message types defined as enumerating
 
 - Push: for push
 - Loop: for loop
 */
enum TestMessageType: UInt8 {
    /// test message type for push
    case Push = 0x00
    /// test message type for loop
    case Loop = 0x01
}

/**
 *  The sid message payload only for testing
 */
struct TestMessage: SIDMessagePayload {
    ///  start value defined as NSData
    var data: NSData
    
    /**
     Initialization point for test message
     
     - parameter message:     the message data defined as NSData
     - parameter commandType: message type for testing, see definition for TestMessageType above
     
     - returns: new Test message instance as Sid messag payload
     */
    init(message: NSData, commandType: TestMessageType) {
        let frameData = NSMutableData()
        var commandType = commandType.rawValue
        var messageLength = UInt16(message.length)
        frameData.appendBytes(&commandType, length: 1)
        frameData.appendBytes(&messageLength, length: 2)
        frameData.appendData(message)
        self.data = frameData
    }
    
    /**
     Initializatio point with raw data
     
     - parameter rawData: the data test message should habe
     
     - returns: new test message instance as SID messag payload
     */
    init(rawData: NSData) {
        data = rawData
    }
    
    /// message data, that test message should contain
    var message: NSData {
        return data.subdataWithRange(NSMakeRange(4, data.length-4))
    }
    
}
