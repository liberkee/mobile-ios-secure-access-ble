//
//  SorcMessagePayload.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  General defined SORC message payload, with Data object type
 */
protocol SorcMessagePayload {

    /// message payload defined as Data
    var data: Data { set get }
}

// MARK: - Extension end point
extension SorcMessagePayload {
}

/**
 *  Message payload with empty bytes
 */
struct EmptyPayload: SorcMessagePayload {
    /// start value as NSData
    var data: Data
    /**
     Initialization point

     - returns: new message payload instance
     */
    init() {
        data = Data(bytes: [0x00])
    }
}
