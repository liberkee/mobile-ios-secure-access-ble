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
    var data = Data()
    /// size as Int
    var mtuSize: Int? {
        let mtu: UInt16 = 0
        var receiver = UInt8(mtu)
        
        (data as Data).copyBytes(to: &receiver, count: MemoryLayout<UInt16>.size)
        //debugPrint("mtu size:\(mtu)")
        return Int(receiver)
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
    init(rawData: Data) {
        self.init()
        data = rawData
    }
}
