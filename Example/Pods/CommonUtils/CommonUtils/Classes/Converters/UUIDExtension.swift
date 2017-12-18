//
//  UUIDExtensions.swift
//  CommonUtils
//
//  Created on 19.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension UUID {

    public init?(data: Data) {
        guard let uuidString = data.uuidString else { return nil }
        self.init(uuidString: uuidString)
    }

    public var lowercasedUUIDString: String {
        return uuidString.lowercased()
    }
}
