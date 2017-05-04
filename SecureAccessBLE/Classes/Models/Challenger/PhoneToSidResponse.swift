//
//  PhoneToSidResponse.swift
//  BLE
//
//  Created by Ke Song on 20.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit

/**
 *  SID message payload for second step Challenge responses to SID
 */
struct PhoneToSidResponse: SIDMessagePayload {
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

     - returns: payload object to SID as NSData
     */
    init(response: [UInt8]) {
        data = Data(bytes: response) // Data.withBytes(response)
    }
}
