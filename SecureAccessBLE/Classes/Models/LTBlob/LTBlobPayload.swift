//
//  LTBlobPayload.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 *  Message payload with blob data
 */
struct LTBlobPayload: SorcMessagePayload {
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
