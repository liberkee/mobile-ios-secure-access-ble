//
//  ServiceGrantRequest.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// The service grant request is forwarded by SORC to the secured object endpoint where the
/// corresponding action is executed
struct ServiceGrantRequest: SorcMessagePayload {
    /// start value as Data
    let data: Data

    /**
     Initialization point

     - returns: Service grant object for service grant request
     - Parameter serviceGrantID: id of the service grant
     */
    init(serviceGrantID: ServiceGrantID) {
        var grantIDValue = serviceGrantID
        data = Data(bytes: &grantIDValue, count: MemoryLayout<ServiceGrantID>.size)
    }

    /**
     Initialization point for Service frant

     - parameter rawData: the raw data service grant contains

     - returns: Service grant object
     */
    init(rawData: Data) {
        data = rawData
    }

    var id: ServiceGrantID {
        var byteArray = [UInt8](repeating: 0x0, count: 2)
        data.copyBytes(to: &byteArray, from: 0 ..< 2)
        return UInt16(byteArray[0])
    }
}
