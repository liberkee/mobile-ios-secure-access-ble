//
//  BulkTransmitMessage.swift
//  SecureAccessBLE_Tests
//
//  Created by Oleg Langer on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct BulkTransmitMessage: SorcMessagePayload {
    let bulkID: [UInt8]
    let type: UInt32
    let metadata: [UInt8]
    let content: [UInt8]
    let data: Data

    enum Error: Swift.Error {
        case bulkIDFormat
    }

    init(bulkID: [UInt8], type: UInt32, metadata: [UInt8], content: [UInt8]) {
        self.bulkID = bulkID
        self.type = type
        self.metadata = metadata
        self.content = content
        var data = Data()
        data.append(SorcMessageID.bulkTransferRequest.rawValue)
        data.append(0x02) // protocol
        data.append(contentsOf: bulkID)
        data.append(type.data)
        data.append(UInt32(metadata.count).data)
        data.append(contentsOf: metadata)
        data.append(UInt32(content.count).data)
        data.append(contentsOf: content)
        self.data = data
    }

    init(mobileBulk: MobileBulk) throws {
        guard let bulkIDData = mobileBulk.bulkId.lowercasedUUIDString.data(using: .utf8) else {
            throw Error.bulkIDFormat
        }
        self.init(bulkID: bulkIDData.bytes,
                  type: mobileBulk.type.rawValue,
                  metadata: mobileBulk.metadata.bytes,
                  content: mobileBulk.content.bytes)
    }
}
