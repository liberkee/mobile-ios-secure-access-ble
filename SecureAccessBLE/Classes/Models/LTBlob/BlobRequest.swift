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
    var data: NSData
    /// The message id as Int
    var blobMessageId: Int {
        var type: UInt32 = 0
        data.getBytes(&type, length: sizeof(UInt32))
        print(type)
        return Int(type)
    }
    
    /**
     Initialization point for Blob request pasyload
     
     - parameter rawData: the message data
     
     - returns: Messag payload object
     */
    init(rawData: NSData) {
        data = rawData
    }
}