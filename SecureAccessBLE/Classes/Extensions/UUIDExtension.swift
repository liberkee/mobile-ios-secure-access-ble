//
//  UUIDExtension.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension UUID {

    init?(data: Data) {
        guard let uuidString = data.uuidString else { return nil }
        self.init(uuidString: uuidString)
    }

    public var lowercasedUUIDString: String {
        return uuidString.lowercased()
    }
}
