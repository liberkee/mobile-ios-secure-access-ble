//
//  SidToPhoneResponse.swift
//  BLE
//
//  Created by Ke Song on 20.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit

/**
 *  To build Message payload for Response from SID at first step of challenge
 */
struct SidToPhoneResponse: SIDMessagePayload {
    /// Initialized Payload as NSData
    var data: NSData
    /// First bytes to challenge
    var b1: [UInt8] {
        let part = self.data.subdataWithRange(NSMakeRange(0, 16))
        let challenge = part.arrayOfBytes()
        return challenge
    }
    
    /// Another bytes to challenge
    var b2: [UInt8] {
        let part = self.data.subdataWithRange(NSMakeRange(16, 16))
        let challenge = part.arrayOfBytes()
        return challenge
    }
    
    /**
     Initialization point
     
     - parameter rawData: incomming raw data for payload
     
     - returns: Message payload for response from SID
     */
    init(rawData: NSData) {
        self.data = rawData
    }
}
