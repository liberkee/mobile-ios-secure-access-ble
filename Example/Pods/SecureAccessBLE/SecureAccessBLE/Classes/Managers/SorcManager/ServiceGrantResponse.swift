//
//  ServiceGrantResponse.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

public typealias ServiceGrantID = UInt16

public struct ServiceGrantResponse: Equatable {
    public enum Status: UInt8 {
        case success = 0x00
        case pending = 0x01
        case failure = 0x02
        case notAllowed = 0x03
    }

    public let sorcID: SorcID
    public let serviceGrantID: ServiceGrantID
    public let status: Status
    public let responseData: String

    public static func == (lhs: ServiceGrantResponse, rhs: ServiceGrantResponse) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.serviceGrantID == rhs.serviceGrantID
            && lhs.status == rhs.status
            && lhs.responseData == rhs.responseData
    }
}
