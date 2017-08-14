//
//  SorcMessagePayload.swift
//  HSM
//
//  Created by Sebastian Stüssel on 20.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  General defined SORC message payload, with NSData object type
 */
protocol SorcMessagePayload {

    /// message payload defined as NSData
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
