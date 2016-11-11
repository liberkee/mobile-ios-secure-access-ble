//
//  SIDMessage.swift
//  TransportTest
//
//  Created by Sebastian Stüssel on 21.08.15.
//  Copyright (c) 2015 Rocket Apes. All rights reserved.
//

import UIKit

/**
 Defines the message type as enumerating, for application layer, session layer and also for testing
 */
enum SIDMessageID: UInt8 {
    /// Challenge message from mobile to SID
    case challengePhone = 0x01
    /// Response challenge message from SID to mobile
    case challengeSidResponse = 0x02
    /// Response message for bad response from SID to mobile
    case badChallengeSidResponse = 0x03
    /// Response message from mobile to SID
    case challengePhoneResonse = 0x04
    /// Response message for bad response from mobile to SID
    case badChallengePhoneResponse = 0x05
    /// Request to get negotiated MTU Size
    case mtuRequest = 0x06
    /// To provide negotiated MTU size
    case mtuReceive = 0x07
    /// To transfer blob or lease token
    case ltAck = 0x09
    /// Test message from mobile to SID
    case phoneTest = 0x10
    /// Response message from SID for testing message
    case sidTest = 0x13
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
    /// Not valid
    case notValid = 0xC8
}

/**
 *  All message come from SID or send to SID have same Message formate
 */
struct SIDMessage {
    var id: SIDMessageID {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, count:1)
        if let validValue = SIDMessageID(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .notValid
        }
    }
    
    /// The real data that a SID Message carried over
    var message: Data {
        return data.subdata(in: 1..<data.count)//NSMakeRange(1, data.count-1))
    }
    
    /// Start value of Sid message as NSData
    var data: Data = Data(bytes: UnsafePointer<UInt8>(([0x00] as [UInt8])), count: 1)
    
    /**
     Initializatio point of SID message instance
     
     - parameter rawData: raw data, SID message should contain
     
     - returns: new SID message instance
     */
    init(rawData: Data) {
        data = rawData
    }
    
    /**
     Optional initializatio point for SID message
     
     - parameter id:      message id defined as SIDMessageID, see description above
     - parameter payload: payload that SID message should contain
     
     - returns: new SID message instance
     */
    init(id: SIDMessageID, payload: SIDMessagePayload) {
        let payloadData = payload.data
        let frameData = NSMutableData()
        var idByte = id.rawValue
        frameData.append(&idByte, length: 1)
        frameData.append(payloadData as Data)
        data = frameData as Data
    }
}
