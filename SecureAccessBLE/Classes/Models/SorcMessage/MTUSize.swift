//
//  MTUSize.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  Init SORC message payload with data and size for MTUSize (request) instance
 */
struct MTUSize: SorcMessagePayload {
    /// start value as NSData
    var data = Data()
    /// size as Int
    var mtuSize: Int? {
        let firstByte = data.bytes.first
        if let firstByte = firstByte {
            let receiver = UInt8(firstByte)
            return Int(receiver)
        }
        return nil
    }

    /**
     Initialization point

     - returns: MTUSize instance as SORC messag payload
     */
    init() {}

    /**
     optional initialization point

     - parameter rawData: raw data the message payload contains

     - returns: MTUSize(request message to SORC) instance as SORC message payload
     */
    init(rawData: Data) {
        self.init()
        data = rawData
    }
}
