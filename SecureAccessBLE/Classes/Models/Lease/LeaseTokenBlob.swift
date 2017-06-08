//
//  LeaseTokenBlob.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 29.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A lease token blob used in establishing a connection to a SORC
public struct LeaseTokenBlob {

    let messageCounter: Int
    let data: String

    public init(messageCounter: Int, data: String) {
        self.messageCounter = messageCounter
        self.data = data
    }
}
