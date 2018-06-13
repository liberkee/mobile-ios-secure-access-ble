//
//  ServiceGrantResponse.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

public typealias ServiceGrantID = UInt16

/// Service grant response
public struct ServiceGrantResponse: Equatable {
    /// Status of the service grant response
    public enum Status: UInt8 {
        /// success
        case success = 0x00
        /// pending
        case pending = 0x01
        /// failure
        case failure = 0x02
        /// not allowed
        case notAllowed = 0x03
    }

    /// Sorc id
    public let sorcID: SorcID
    /// Service grant id
    public let serviceGrantID: ServiceGrantID
    /// Status
    public let status: Status
    /// Response data
    public let responseData: String

    public static func == (lhs: ServiceGrantResponse, rhs: ServiceGrantResponse) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.serviceGrantID == rhs.serviceGrantID
            && lhs.status == rhs.status
            && lhs.responseData == rhs.responseData
    }
}
