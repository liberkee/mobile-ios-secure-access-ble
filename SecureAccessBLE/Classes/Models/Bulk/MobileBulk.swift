//
//  MobileBulk.swift
//  SecureAccessBLE
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public struct MobileBulk {
    enum Error: Swift.Error {
        case metadataFormatError
    }

    public enum BulkType: Int {
        case configBulk = 10
        case applyBulk = 20
    }

    public let bulkId: [UInt8]
    public let type: Int
    public let metadata: [UInt8]
    public let content: [UInt8]

    public init(bulkID: String, type: BulkType, metadata: String, content: [UInt8]) throws {
        guard let asciiMetadata = metadata.data(using: .ascii) else {
            throw Error.metadataFormatError
        }

        bulkId = bulkID.utf8Array
        self.type = type.rawValue
        self.metadata = asciiMetadata.bytes
        self.content = content
    }
}

extension String {
    var utf8Array: [UInt8] {
        return Array(utf8)
    }
}
