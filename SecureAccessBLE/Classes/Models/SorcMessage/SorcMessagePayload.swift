//
//  SorcMessagePayload.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  General defined SORC message payload, with Data object type
 */
protocol SorcMessagePayload {
    /// message payload defined as Data
    var data: Data { get }
}

// MARK: - Extension end point

extension SorcMessagePayload {}

/**
 *  Message payload with empty bytes
 */
struct EmptyPayload: SorcMessagePayload {
    /// start value as Data
    let data: Data
    /**
     Initialization point

     - returns: new message payload instance
     */
    init() {
        data = Data([0x00])
    }
}
