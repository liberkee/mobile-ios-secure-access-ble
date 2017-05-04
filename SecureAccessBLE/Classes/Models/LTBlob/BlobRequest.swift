//
//  BlobRequest.swift
//  HSM
//
//  Created by Sebastian Stüssel on 05.02.16.
//  Copyright © 2016 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  To build MessagePayload as Blob request sending to SID
 */
struct BlobRequest: SIDMessagePayload {
    /// Start message payload as NSData for blob request
    var data: Data
    /// The message id as Int
    var blobMessageId: Int {
        let type: UInt32 = 0
        var receiveData = UInt8(type)
        (data as Data).copyBytes(to: &receiveData, count: MemoryLayout<UInt32>.size)
        debugPrint(receiveData)
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
