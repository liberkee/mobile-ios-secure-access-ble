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

    /// Lease token id
    public let id: String
    /// Lease id
    public let leaseID: String
    /// Sorc id
    public let sorcID: SorcID
    /// Sorc access key
    public let sorcAccessKey: String

    /// Initializer for LeaseToken
    ///
    /// - Parameters:
    ///   - id: lease token id
    ///   - leaseID: lease id
    ///   - sorcID: sorc id
    ///   - sorcAccessKey: sorc access key
    /// - Throws: throws error if `sorcAccessKey` is empty
    public init(id: String, leaseID: String, sorcID: SorcID, sorcAccessKey: String) throws {
        self.id = id
        self.leaseID = leaseID
        self.sorcID = sorcID

        guard !sorcAccessKey.isEmpty else {
            throw Error.sorcAccessKeyIsEmpty
        }
        self.sorcAccessKey = sorcAccessKey
    }

    public static func == (lhs: LeaseToken, rhs: LeaseToken) -> Bool {
        return lhs.id == rhs.id
            && lhs.leaseID == rhs.leaseID
            && lhs.sorcID == rhs.sorcID
            && lhs.sorcAccessKey == rhs.sorcAccessKey
    }
}
