//
//  ServiceGrant.swift
//  HSM
//
//  Created by Sebastian Stüssel on 19.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 Descripts the service grant message that requests from Mobile device
 */
enum ServiceGrantID: UInt16 {
    /// To unlock vehicles door
    case unlock = 0x01
    /// To lock vehicles door
    case lock = 0x02
    /// To call up vehicles lock status
    case lockStatus = 0x03
    /// To enable Ignition
    case enableIgnition = 0x04
    /// To disable Ignition
    case disableIgnition = 0x05
    /// To call up Ignition status
    case ignitionStatus = 0x06
    /// Others
    case notValid = 0xFF
}

/**
 *  SID messagepayload with service grant id
 */
protocol ServiceGrant: SIDMessagePayload {
    /**
     Initilization point

     - returns: Service grant object
     */
    init()

    /**
     optional init with grant id

     - parameter grantID: ID that Service grant should have

     - returns: new Service grant object
     */
    init(grantID: ServiceGrantID)

    /**
     optional init with data

     - parameter rawData: raw data the service grant contains

     - returns: new service grant object
     */
    init(rawData: Data)
}

// MARK: - extension endpoint
extension ServiceGrant {
    /**
     optional init with grant id

     - parameter grantID: ID that Service grant should have

     - returns: new Service grant object
     */
    init(grantID: ServiceGrantID) {
        let frameData = NSMutableData()
        var grantIDValue = grantID.rawValue
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

    ///  service grant id, see definition for ServiceGrantID above
    var id: ServiceGrantID {
        var byteArray = [UInt8](repeating: 0x0, count: 2)
        (data as Data).copyBytes(to: &byteArray, from: 0 ..< 2) // NSMakeRange(0, 2))
        let rawValue = UInt16(byteArray[0])

        if let validValue = ServiceGrantID(rawValue: rawValue) {
            return validValue
        } else {
            return .notValid
        }
    }
}

/// The service grant request is forwarded by SID to the secured object endpoint where the
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
