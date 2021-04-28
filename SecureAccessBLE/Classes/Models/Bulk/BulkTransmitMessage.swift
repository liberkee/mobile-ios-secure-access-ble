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
        guard let bulkIDData = mobileBulk.bulkId.asUInt8Array() else {
            throw Error.bulkIDFormat
        }
        self.init(bulkID: bulkIDData,
                  type: UInt32(mobileBulk.type.rawValue),
                  metadata: mobileBulk.metadata.bytes,
                  content: mobileBulk.content.bytes)
    }
}

public extension UUID {
    func asUInt8Array() -> [UInt8]? {
        let (u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16) = uuid
        return [u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, u16]
    }
}
