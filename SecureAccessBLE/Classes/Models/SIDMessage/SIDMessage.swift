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
    case ChallengePhone = 0x01
    /// Response challenge message from SID to mobile
    case ChallengeSidResponse = 0x02
    /// Response message for bad response from SID to mobile
    case BadChallengeSidResponse = 0x03
    /// Response message from mobile to SID
    case ChallengePhoneResonse = 0x04
    /// Response message for bad response from mobile to SID
    case BadChallengePhoneResponse = 0x05
    /// Request to get negotiated MTU Size
    case MTURequest = 0x06
    /// To provide negotiated MTU size
    case MTUReceive = 0x07
    /// To transfer blob or lease token
    case LTAck = 0x09
    /// Test message from mobile to SID
    case PhoneTest = 0x10
    /// Response message from SID for testing message
    case SidTest = 0x13
    /// Deprecated only for testing
    case LTBlobRequest = 0x0A
    /// Deprecated ??
    case LTBlob = 0x0B
    /// HeartBeat Request
    case HeartBeatRequest = 0x0C
    /// HeartBeat Response
    case HeartBeatResponse = 0x0D
    /// Service grant message
    case ServiceGrant = 0x20
    /// Service grant trigger message
    case ServiceGrantTrigger = 0x30
    /// Not valid
    case NotValid = 0xC8
}

/**
 *  All message come from SID or send to SID have same Message formate
 */
struct SIDMessage {
    var id: SIDMessageID {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, length:1)
        if let validValue = SIDMessageID(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .NotValid
        }
    }
    
    /// The real data that a SID Message carried over
    var message: NSData {
        return data.subdataWithRange(NSMakeRange(1, data.length-1))
    }
    
    /// Start value of Sid message as NSData
    var data: NSData = NSData(bytes: ([0x00] as [UInt8]), length: 1)
    
    /**
     Initializatio point of SID message instance
     
     - parameter rawData: raw data, SID message should contain
     
     - returns: new SID message instance
     */
    init(rawData: NSData) {
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
        frameData.appendBytes(&idByte, length: 1)
        frameData.appendData(payloadData)
        data = frameData
    }
}
