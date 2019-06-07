//
//  BlobRequest.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  To build MessagePayload as Blob request sending to SORC
 */
struct BlobRequest: SorcMessagePayload {
    enum Error: Swift.Error {
        case invalidSize
    }

    var data: Data {
        get {
            return backingData
        }
        set {}
    }

    // private property holding data since we don't want it to be mutated after creation
    private let backingData: Data

    /// blob message counter
    var blobMessageCounter: Int {
        let result: UInt32 = data.subdata(in: 1 ..< data.count).withUnsafeBytes {
            UInt32(bigEndian: $0.load(as: UInt32.self))
        }
        return Int(result)
    }

    /**
     Initialization point for Blob request payload

     - parameter rawData: the message data

     - returns: Message payload object
     */
    init(rawData: Data) throws {
        guard rawData.count == 5 else {
            throw Error.invalidSize
        }
        backingData = rawData
    }
}
