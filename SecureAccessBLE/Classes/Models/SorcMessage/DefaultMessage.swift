//
//  DefaultMessage.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  SORC message containing raw data
 */
struct DefaultMessage: SorcMessagePayload {
    /// start value as NSData
    var data = Data()

    /**
     Initialization point

     - returns: DefaultMessage instance as SORC messag payload
     */
    init() {}

    /**
     optional initialization point

     - parameter rawData: raw data the message payload contains

     - returns: DefaultMessage(request message to SORC) instance as SORC message payload
     */
    init(rawData: Data) {
        self.init()
        data = rawData
    }
}
