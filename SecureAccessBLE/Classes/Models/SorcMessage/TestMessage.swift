//
//  TestMessage.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

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
    ///  start value defined as Data
    let data: Data

    /**
     Initialization point for test message

     - parameter message:     the message data defined as Data
     - parameter commandType: message type for testing, see definition for TestMessageType above

     - returns: new Test message instance as SORC messag payload
     */
    init(message: Data, commandType: TestMessageType) {
        var frameData = Data()
        let commandType = commandType.rawValue
        let messageLength = UInt16(message.count)
        frameData.append(commandType.data)
        frameData.append(messageLength.data)
        frameData.append(message)
        data = frameData
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
