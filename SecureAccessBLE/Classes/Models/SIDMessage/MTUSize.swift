//
//  MTUSize.swift
//  HSM
//
//  Created by Sebastian Stüssel on 28.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Init Sid message payload with data and size for MTUSize (request) instance
 */
struct MTUSize: SIDMessagePayload {
    /// start value as NSData
    var data = NSData()
    /// size as Int
    var mtuSize: Int? {
        var mtu: UInt16 = 0
        data.getBytes(&mtu, length: sizeof(UInt16))
        //print("mtu size:\(mtu)")
        return Int(mtu)
    }
    /**
     Initialization point
     
     - returns: MTUSize instance as Sid messag payload
     */
    init() {
    }
    
    /**
     optional initialization point
     
     - parameter rawData: raw data the message payload contains
     
     - returns: MTUSize(request message to SID) instance as sid message payload
     */
    init(rawData: NSData) {
        self.init()
        data = rawData
    }
}