//
//  LeaseToken.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 29.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A lease token used in establishing a connection to a SORC
public struct LeaseToken {

    public let id: String
    public let leaseID: String
    public let sorcID: SorcID
    public let sorcAccessKey: String

    public init(id: String, leaseID: String, sorcID: SorcID, sorcAccessKey: String) {
        self.id = id
        self.leaseID = leaseID
        self.sorcID = sorcID
        self.sorcAccessKey = sorcAccessKey
    }
}
