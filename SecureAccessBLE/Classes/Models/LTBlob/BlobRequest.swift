//
//  BlobRequest.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  To build MessagePayload as Blob request sending to SORC
 */
struct BlobRequest: SorcMessagePayload {
    /// Start message payload as NSData for blob request
    var data: Data
    /// The message id as Int
    var blobMessageID: Int {
        let type: UInt32 = 0
        var receiveData = UInt8(type)
        (data as Data).copyBytes(to: &receiveData, count: MemoryLayout<UInt32>.size)
        return Int(receiveData)
    }

    /**
     Initialization point for Blob request pasyload

     - parameter rawData: the message data

     - returns: Messag payload object
     */
    init(rawData: Data) {
        data = rawData
    }
}
