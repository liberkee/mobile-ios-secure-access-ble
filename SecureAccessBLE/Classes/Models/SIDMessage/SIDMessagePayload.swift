//
//  SIDMessagePayload.swift
//  HSM
//
//  Created by Sebastian Stüssel on 20.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  General defined SID message payload, with NSData object type
 */
protocol SIDMessagePayload {
    
    /// message payload defined as NSData
    var data: NSData { set get }
}

// MARK: - Extension end point
extension SIDMessagePayload {
}

/**
 *  Message payload with empty bytes
 */
struct EmptyPayload: SIDMessagePayload {
    /// start value as NSData
    var data: NSData
    /**
     Initialization point
     
     - returns: new message payload instance
     */
    init() {
        self.data = NSData.withBytes([0x00])
    }
    
}