//
//  ServiceGrantResponse.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/// The ID that specifies the type of a service grant
public typealias ServiceGrantID = UInt16

/// The response to a service grant request
public struct ServiceGrantResponse: Equatable {
    /// The ID of the SORC that received the service grant request
    public let sorcID: SorcID

    /// The ID of the requested service grant
    public let serviceGrantID: ServiceGrantID

    /// The current status of the service grant request
    public let status: Status

    /// The response data
    public let responseData: String

    /// The status a service grant request can be in
    public enum Status: UInt8 {
        /// The request finished with success
        case success = 0x00

        /// The request is still pending
        case pending = 0x01

        /// The request finished with failure
        case failure = 0x02

        /// The request is not allowed
        case notAllowed = 0x03
    }

    /// :nodoc:
    public static func == (lhs: ServiceGrantResponse, rhs: ServiceGrantResponse) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.serviceGrantID == rhs.serviceGrantID
            && lhs.status == rhs.status
            && lhs.responseData == rhs.responseData
    }
}
