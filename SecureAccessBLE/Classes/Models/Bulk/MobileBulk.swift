//
//  MobileBulk.swift
//  SecureAccessBLE
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public struct MobileBulk: Equatable {
    enum Error: Swift.Error {
        case metadataFormat
        case contentFormat
    }

    public enum BulkType: Int {
        case configBulk = 10
        case applyBulk = 20
    }

    public let bulkId: UUID
    public let type: BulkType
    public let metadata: Data
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
