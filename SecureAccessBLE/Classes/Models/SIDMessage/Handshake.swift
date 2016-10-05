//
//  Handshake.swift
//  HSM
//
//  Created by Sebastian Stüssel on 29.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Defines message payload from mobile to SID
 */
struct Handshake: SIDMessagePayload {
    /// start value as NSData
    var data: NSData
    /**
     Initialization point for handshake
     
     - parameter deviceId: device id as String
     - parameter sidId:    sid id as String
     - parameter leaseId:  lease token id as String
     
     - returns: Hand shake object as Sid message payload
     */
    init(deviceId: String, sidId: String, leaseId: String) {
        let frameData = NSMutableData()
        frameData.appendData(deviceId.dataUsingEncoding(NSASCIIStringEncoding)!)
        frameData.appendData(sidId.dataUsingEncoding(NSASCIIStringEncoding)!)
        
        frameData.appendData(leaseId.dataUsingEncoding(NSASCIIStringEncoding)!)
        let challenge = [UInt8](count: 16, repeatedValue: 0x0)
        frameData.appendData(NSData(bytes: challenge, length: challenge.count))
        self.data = frameData
    }
}