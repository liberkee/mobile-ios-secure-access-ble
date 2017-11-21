//
//  LeaseTokenBlob.swift
//  SecureAccessBLE
//
//  Created on 29.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A lease token blob used in establishing a connection to a SORC
public struct LeaseTokenBlob: Equatable {

    enum Error: Swift.Error {
        case dataIsEmpty
    }

    public let messageCounter: Int
    public let data: String

    public init(messageCounter: Int, data: String) throws {
        self.messageCounter = messageCounter

        guard !data.isEmpty else {
            throw Error.dataIsEmpty
        }
        self.data = data
    }

    public static func ==(lhs: LeaseTokenBlob, rhs: LeaseTokenBlob) -> Bool {
        return lhs.messageCounter == rhs.messageCounter
            && lhs.data == rhs.data
    }
}
