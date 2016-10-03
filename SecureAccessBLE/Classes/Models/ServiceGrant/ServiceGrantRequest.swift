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
    case Unlock = 0x01
    /// To lock vehicles door
    case Lock = 0x02
    /// To call up vehicles lock status
    case LockStatus = 0x03
    /// To enable Ignition
    case EnableIgnition = 0x04
    /// To disable Ignition
    case DisableIgnition = 0x05
    /// To call up Ignition status
    case IgnitionStatus = 0x06
    /// Others
    case NotValid = 0xFF
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
    init(rawData: NSData)
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
        frameData.appendBytes(&grantIDValue, length: 2)
        self.init()
        self.data = frameData
    }
    
    /**
     Initialization point for Service frant
     
     - parameter rawData: the raw data service grant contains
     
     - returns: Service grant object
     */
    init(rawData: NSData) {
        self.init()
        data = rawData
    }
    
    ///  service grant id, see definition for ServiceGrantID above
    var id: ServiceGrantID {
        var byteArray = [UInt8](count: 2, repeatedValue: 0x0)
        data.getBytes(&byteArray, range: NSMakeRange(0, 2))
        let rawValue = UInt16(byteArray[0])
        
        if let validValue = ServiceGrantID(rawValue: rawValue) {
            return validValue
        } else {
            return .NotValid
        }
    }
}

/// The service grant request is forwarded by SID to the secured object endpoint where the
/// corresponding action is executed
struct ServiceGrantRequest: ServiceGrant {
    /// start value as NSData
    var data: NSData
    
    /**
     Initialization point
     
     - returns: Service grant object for service grant request
    */
    init () {
        data = NSData()
    }
}