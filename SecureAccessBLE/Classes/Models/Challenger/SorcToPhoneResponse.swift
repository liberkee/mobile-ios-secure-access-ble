//
//  SorcToPhoneResponse.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 *  To build Message payload for Response from SORC at first step of challenge
 */
struct SorcToPhoneResponse: SorcMessagePayload {
    /// Initialized Payload as NSData
    var data: Data
    /// First bytes to challenge
    var b1: [UInt8] {
        let part = data.subdata(in: 0 ..< 16) // NSMakeRange(0, 16))
        let challenge = (part as Data).bytes
        return challenge
    }

    /// Another bytes to challenge
    var b2: [UInt8] {
        let part = data.subdata(in: 16 ..< 32) // NSMakeRange(16, 16))
        let challenge = (part as Data).bytes
        return challenge
    }

    /**
     Initialization point

     - parameter rawData: incomming raw data for payload

     - returns: Message payload for response from SORC
     */
    init(rawData: Data) {
        data = rawData
    }
}