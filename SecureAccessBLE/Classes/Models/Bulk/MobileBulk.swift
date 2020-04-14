//
//  MobileBulk.swift
//  SecureAccessBLE
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

// Mobile bulk for transmition
/// :nodoc:
public struct MobileBulk: Equatable {
    // Error which can be thrown by `MobileBulk`
    enum Error: Swift.Error {
        // metadata not in a correct format
        case metadataFormat
        // content not in a correct format
        case contentFormat
    }

    // Type of the bulk
    public enum BulkType: Int {
        // config bulk
        case configBulk = 10
        // apply bulk
        case applyBulk = 20
    }

    // bulk id
    public let bulkId: UUID
    // bulk type
    public let type: BulkType
    // meta data
    public let metadata: Data
    // content
    public let content: Data

    public init(bulkID: UUID, type: BulkType, metadata: String, content: String) throws {
        guard let asciiMetadata = metadata.data(using: .ascii) else {
            throw Error.metadataFormat
        }

        guard let contentData = Data(base64Encoded: content) else {
            throw Error.contentFormat
        }

        bulkId = bulkID
        self.type = type
        self.metadata = asciiMetadata
        self.content = contentData
    }
}
