//
//  PhoneToSorcResponse.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 *  SORC message payload for second step Challenge responses to SORC
 */
struct PhoneToSorcResponse: SorcMessagePayload {
    /// Initialized Payload as Data
    let data: Data
    /// challenge bytes
    var challenge: [UInt8] {
        let challenge = data.bytes
        return challenge
    }

    /**
     Initialization end point

     - parameter response: response bytes

     - returns: payload object to SORC as Data
     */
    init(response: [UInt8]) {
        data = Data(response)
    }
}
