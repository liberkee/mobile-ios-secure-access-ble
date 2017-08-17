//
//  Handshake.swift
//  HSM
//
//  Created by Sebastian Stüssel on 29.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Defines message payload from mobile to SORC
 */
struct Handshake: SorcMessagePayload {
    /// start value as NSData
    var data: Data
    /**
     Initialization point for handshake

     - parameter deviceID: device id as String
     - parameter sorcID: SORC ID as String
     - parameter leaseID:  lease token id as String

     - returns: Hand shake object as SORC message payload
     */
    init(deviceID: String, sorcID: SorcID, leaseID: String) {
        let frameData = NSMutableData()
        frameData.append(deviceID.data(using: String.Encoding.ascii)!)
        frameData.append(sorcID.data(using: String.Encoding.ascii)!)

        frameData.append(leaseID.data(using: String.Encoding.ascii)!)
        let challenge = [UInt8](repeating: 0x0, count: 16)
        frameData.append(Data(bytes: UnsafePointer<UInt8>(challenge), count: challenge.count))
        data = frameData as Data
    }
}
