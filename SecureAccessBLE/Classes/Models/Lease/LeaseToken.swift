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

    let id: String
    let leaseId: String
    let sorcId: String
    let sorcAccessKey: String

    public init(id: String, leaseId: String, sorcId: String, sorcAccessKey: String) {
        self.id = id
        self.leaseId = leaseId
        self.sorcId = sorcId
        self.sorcAccessKey = sorcAccessKey
    }
}
