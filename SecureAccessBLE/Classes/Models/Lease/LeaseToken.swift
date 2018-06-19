//
//  LeaseToken.swift
//  SecureAccessBLE
//
//  Created on 29.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A lease token used in establishing a connection to a SORC
public struct LeaseToken: Equatable {
    enum Error: Swift.Error {
        case sorcAccessKeyIsEmpty
    }

    /// The ID of the lease token
    public let id: String

    /// The ID of the lease
    public let leaseID: String

    /// The ID of the SORC
    public let sorcID: SorcID

    /// The SORC access key
    public let sorcAccessKey: String

    /// :nodoc:
    public static func == (lhs: LeaseToken, rhs: LeaseToken) -> Bool {
        return lhs.id == rhs.id
            && lhs.leaseID == rhs.leaseID
            && lhs.sorcID == rhs.sorcID
            && lhs.sorcAccessKey == rhs.sorcAccessKey
    }

    /// Lease Token Initializer
    ///
    /// - Parameters:
    ///   - id: The ID of the lease token
    ///   - leaseID: The ID of the lease
    ///   - sorcID: The ID of the SORC
    ///   - sorcAccessKey: The SORC access key
    /// - Throws: error if the SORC access key is empty
    public init(id: String, leaseID: String, sorcID: SorcID, sorcAccessKey: String) throws {
        self.id = id
        self.leaseID = leaseID
        self.sorcID = sorcID

        guard !sorcAccessKey.isEmpty else {
            throw Error.sorcAccessKeyIsEmpty
        }
        self.sorcAccessKey = sorcAccessKey
    }
}
