//
//  LTBlobPayload.swift
//  HSM
//
//  Created by Sebastian Stüssel on 29.01.16.
//  Copyright © 2016 Sebastian Stüssel. All rights reserved.
//

import UIKit

/**
 *  Message payload with blob data
 */
struct LTBlobPayload: SIDMessagePayload {
    /// start Payload as NSData
    var data: Data
    /**
     Initialization point for Lease token blob payload

     - parameter blobData: the incomming blob data as String

     - returns: message payload as lease token blob data
     */
    init?(blobData: String) {
        data = Data(base64Encoded: blobData, options: Data.Base64DecodingOptions())!
    }
}
