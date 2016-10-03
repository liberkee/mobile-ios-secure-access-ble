//
//  ServiceGrantTrigger.swift
//  HSM
//
//  Created by Sebastian Stüssel on 20.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Service grant trigger comes from SID peripheral
 */
struct ServiceGrantTrigger: ServiceGrant {
    /**
     Defines the Service Grant Status as enumerating, answered from SID peripheral
     
     - Success:    Success status
     - Pending:    Pending status
     - Failure:    Did failed status
     - NotAllowed: Not allowed status
     */
    enum ServiceGrantStatus: UInt8 {
        case Success = 0x00
        case Pending = 0x01
        case Failure = 0x02
        case NotAllowed = 0x03
    }
    
    /**
     Is the Service Grant response to a Trigger service Grant request message defined as enumerating
     
     - Locked:   Door was Locked
     - Unlocked: Door was Unlocked
     - Enabled:  Ignition was enabled
     - Disabled: Ignition was disabled
     - Unknown:  Unknown result
     */
    enum ServiceGrantResult: String {
        case Locked = "LOCKED"
        case Unlocked = "UNLOCKED"
        case Enabled = "ENABLED"
        case Disabled = "DISABLED"
        case Unknown = "UNKNOWN"
    }
    
    /// start value as NSData
    var data: NSData
    
    /**
     Initialization point
     
     - returns: service grant trigger
     */
    init () {
        data = NSData()
    }
    
    /**
     Optional initialization point
     
     - parameter grantID: ID, service grant trigger should habe
     - parameter status:  the trigger status defined as ServiceGrantStatus
     - parameter message: message as String
     
     - returns: service grant trigger object
     */
    init(grantID: ServiceGrantID, status: ServiceGrantStatus, message: String?) {
        self.init(grantID: grantID)
        let frameData = NSMutableData()
        var statusByte = status.rawValue
        frameData.appendBytes(&statusByte, length: 1)
        if let data = message?.dataUsingEncoding(NSASCIIStringEncoding) {
            frameData.appendData(data)
        }
        data = frameData
    }
    
    /// Returns one from ServiceGrantStatus
    var status: ServiceGrantStatus {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, range: NSMakeRange(2, 1))
        if let status = ServiceGrantStatus(rawValue: byteArray[0]) {
            return status
        } else {
            return .NotAllowed
        }
    }
    
    /// Returns one from ServiceGrantStatus
    var result: ServiceGrantResult {
        if data.length > 3 {
            let messageData = data.subdataWithRange(NSMakeRange(3, data.length-3))
            guard let string = NSString(data: messageData, encoding: NSASCIIStringEncoding) as? String else {
                return .Unknown
            }
            let cleanString = string.stringByTrimmingCharactersInSet(NSCharacterSet.controlCharacterSet())
            if let resultCode  = ServiceGrantResult(rawValue: cleanString) {
                return resultCode
            } else {
                return .Unknown
            }
        }
        return .Unknown
    }
}