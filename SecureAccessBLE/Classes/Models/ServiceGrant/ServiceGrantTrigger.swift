//
//  ServiceGrantTrigger.swift
//  HSM
//
//  Created by Sebastian Stüssel on 20.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Service grant trigger comes from SORC peripheral
 */
struct ServiceGrantTrigger: ServiceGrant {
    /**
     Defines the Service Grant Status as enumerating, answered from SORC peripheral

     - Success:    Success status
     - Pending:    Pending status
     - Failure:    Did failed status
     - NotAllowed: Not allowed status
     */
    enum ServiceGrantStatus: UInt8 {
        case success = 0x00
        case pending = 0x01
        case failure = 0x02
        case notAllowed = 0x03
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
        case locked = "LOCKED"
        case unlocked = "UNLOCKED"
        case enabled = "ENABLED"
        case disabled = "DISABLED"
        case unknown = "UNKNOWN"
    }

    /// start value as NSData
    var data: Data

    /**
     Initialization point

     - returns: service grant trigger
     */
    init() {
        data = Data()
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
        frameData.append(&statusByte, length: 1)
        if let data = message?.data(using: String.Encoding.ascii) {
            frameData.append(data)
        }
        data = frameData as Data
    }

    /// Returns one from ServiceGrantStatus
    var status: ServiceGrantStatus {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, from: 2 ..< 3) // NSMakeRange(2, 1))
        if let status = ServiceGrantStatus(rawValue: byteArray[0]) {
            return status
        } else {
            return .notAllowed
        }
    }

    /// Returns one from ServiceGrantStatus
    var result: ServiceGrantResult {
        if data.count > 3 {
            let messageData = data.subdata(in: 3 ..< data.count) // NSMakeRange(3, data.count-3))
            guard let string = String(data: messageData, encoding: .ascii) else {
                return .unknown
            }
            let cleanString = string.trimmingCharacters(in: CharacterSet.controlCharacters)
            if let resultCode = ServiceGrantResult(rawValue: cleanString) {
                return resultCode
            } else {
                return .unknown
            }
        }
        return .unknown
    }
}
