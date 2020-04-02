//
//  SorcMessage.swift
//  TransportTest
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 Defines the message type as enumerating, for application layer, session layer and also for testing
 */
enum SorcMessageID: UInt8 {
    /// Challenge message from mobile to SORC
    case challengePhone = 0x01
    /// Response challenge message from SORC to mobile
    case challengeSorcResponse = 0x02
    /// Response message for bad response from SORC to mobile
    case badChallengeSorcResponse = 0x03
    /// Response message from mobile to SORC
    case challengePhoneResponse = 0x04
    /// Response message for bad response from mobile to SORC
    case badChallengePhoneResponse = 0x05
    /// To transfer blob or lease token
    case ltAck = 0x09
    /// Test message from mobile to SORC
    case phoneTest = 0x10
    /// Response message from SORC for testing message
    case sorcTest = 0x13
    /// Deprecated only for testing
    case ltBlobRequest = 0x0A
    /// Deprecated ??
    case ltBlob = 0x0B
    /// HeartBeat Request
    case heartBeatRequest = 0x0C
    /// HeartBeat Response
    case heartBeatResponse = 0x0D
    /// Service grant message
    case serviceGrant = 0x20
    /// Service grant trigger message
    case serviceGrantTrigger = 0x30
    /// Request message for bulk transfer from mobile to SORC
    case bulkTranferRequest = 0x60
    /// Response message for bulk transfer from SORC to mobile
    case bulkTranferResponse = 0x61
    /// Not valid
    case notValid = 0xC8
}

/**
 *  All message come from SORC or send to SORC have same Message formate
 */
struct SorcMessage: Equatable {
    var id: SorcMessageID {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        data.copyBytes(to: &byteArray, count: 1)
        if let validValue = SorcMessageID(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .notValid
        }
    }

    /// The real data that a SORC Message carried over
    var message: Data {
        return data.count > 1 ? data.subdata(in: 1 ..< data.count) : Data()
    }

    /// Start value of SORC message as Data
    let data: Data

    /**
     Initialization point of SORC message instance

     - parameter rawData: raw data, SORC message should contain

     - returns: new SORC message instance
     */
    init(rawData: Data) {
        data = rawData
    }

    /**
     Optional initializatio point for SORC message

     - parameter id:      message id defined as SorcMessageID, see description above
     - parameter payload: payload that SORC message should contain

     - returns: new SORC message instance
     */
    init(id: SorcMessageID, payload: SorcMessagePayload) {
        let payloadData = payload.data
        var frameData = Data()
        frameData.append(id.rawValue)
        frameData.append(payloadData as Data)
        data = frameData
    }
}
