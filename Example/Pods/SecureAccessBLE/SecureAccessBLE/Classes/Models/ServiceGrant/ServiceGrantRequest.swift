//
//  ServiceGrantRequest.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/**
 *  SORC messagepayload with service grant id
 */
protocol ServiceGrant: SorcMessagePayload {
    /**
     Initilization point

     - returns: Service grant object
     */
    init()

    /**
     optional init with data

     - parameter rawData: raw data the service grant contains

     - returns: new service grant object
     */
    init(rawData: Data)
}

// MARK: - extension endpoint

extension ServiceGrant {
    init(serviceGrantID: ServiceGrantID) {
        let frameData = NSMutableData()
        var grantIDValue = serviceGrantID
        frameData.append(&grantIDValue, length: 2)
        self.init()
        data = frameData as Data
    }

    /**
     Initialization point for Service frant

     - parameter rawData: the raw data service grant contains

     - returns: Service grant object
     */
    init(rawData: Data) {
        self.init()
        data = rawData
    }

    var id: ServiceGrantID {
        var byteArray = [UInt8](repeating: 0x0, count: 2)
        data.copyBytes(to: &byteArray, from: 0 ..< 2)
        return UInt16(byteArray[0])
    }
}

/// The service grant request is forwarded by SORC to the secured object endpoint where the
/// corresponding action is executed
struct ServiceGrantRequest: ServiceGrant {
    /// start value as NSData
    var data: Data

    /**
     Initialization point

     - returns: Service grant object for service grant request
     */
    init() {
        data = Data()
    }
}
