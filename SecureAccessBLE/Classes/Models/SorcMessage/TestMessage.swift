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
    case push = 0x00
    /// test message type for loop
    case loop = 0x01
}

/**
 *  The SORC message payload only for testing
 */
struct TestMessage: SorcMessagePayload {
    ///  start value defined as NSData
    var data: Data

    /**
     Initialization point for test message

     - parameter message:     the message data defined as NSData
     - parameter commandType: message type for testing, see definition for TestMessageType above

     - returns: new Test message instance as SORC messag payload
     */
    init(message: Data, commandType: TestMessageType) {
        let frameData = NSMutableData()
        var commandType = commandType.rawValue
        var messageLength = UInt16(message.count)
        frameData.append(&commandType, length: 1)
        frameData.append(&messageLength, length: 2)
        frameData.append(message)
        data = frameData as Data
    }

    /**
     Initializatio point with raw data

     - parameter rawData: the data test message should habe

     - returns: new test message instance as SORC messag payload
     */
    init(rawData: Data) {
        data = rawData
    }

    /// message data, that test message should contain
    var message: Data {
        return data.subdata(in: 4 ..< data.count) // NSMakeRange(4, data.count-4))
    }
}
