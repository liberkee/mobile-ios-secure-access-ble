//
//  PhoneToSorcResponse.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 *  SORC message payload for second step Challenge responses to SORC
 */
struct PhoneToSorcResponse: SorcMessagePayload {
    /// Initialized Payload as NSData
    var data: Data
    /// challenge bytes
    var challenge: [UInt8] {
        let challenge = data.bytes // arrayOfBytes()
        return challenge
    }

    /**
     Initialization end point

     - parameter response: response bytes

     - returns: payload object to SORC as NSData
     */
    init(response: [UInt8]) {
        data = Data(bytes: response) // Data.withBytes(response)
    }
}
