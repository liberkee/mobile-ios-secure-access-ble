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
    var data: Data
    /**
     Initialization point for handshake

     - parameter deviceId: device id as String
     - parameter sidId:    sid id as String
     - parameter leaseId:  lease token id as String

     - returns: Hand shake object as Sid message payload
     */
    init(deviceId: String, sidId: String, leaseId: String) {
        let frameData = NSMutableData()
        frameData.append(deviceId.data(using: String.Encoding.ascii)!)
        frameData.append(sidId.data(using: String.Encoding.ascii)!)

        frameData.append(leaseId.data(using: String.Encoding.ascii)!)
        let challenge = [UInt8](repeating: 0x0, count: 16)
        frameData.append(Data(bytes: UnsafePointer<UInt8>(challenge), count: challenge.count))
        data = frameData as Data
    }
}
