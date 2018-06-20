//
//  LeaseTokenBlob.swift
//  SecureAccessBLE
//
//  Created on 29.05.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A lease token BLOB used in establishing a connection to a SORC
public struct LeaseTokenBlob: Equatable {
    enum Error: Swift.Error {
        case dataIsEmpty
    }

    /// The counter that indicates whether the lease token BLOB is outdated
    public let messageCounter: Int

    /// The encrypted lease token BLOB data
    public let data: String

    /// :nodoc:
    public static func == (lhs: LeaseTokenBlob, rhs: LeaseTokenBlob) -> Bool {
        return lhs.messageCounter == rhs.messageCounter
            && lhs.data == rhs.data
    }

    /// LeaseTokenBlob Initializer
    ///
    /// - Parameters:
    ///   - messageCounter: The counter that indicates whether the lease token BLOB is outdated
    ///   - data: The encrypted lease token BLOB data
    /// - Throws: error if the data is empty
    public init(messageCounter: Int, data: String) throws {
        self.messageCounter = messageCounter

        guard !data.isEmpty else {
            throw Error.dataIsEmpty
        }
        self.data = data
    }
}
