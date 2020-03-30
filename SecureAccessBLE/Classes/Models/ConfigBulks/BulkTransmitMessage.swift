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

    private let messageID: UInt8 = 0x60

    init(bulkID: [UInt8], type: UInt32, metadata: [UInt8], content: [UInt8]) {
        self.bulkID = bulkID
        self.type = type
        self.metadata = metadata
        self.content = content
        var data = Data()
        data.append(messageID)
        data.append(0x02) // protocol
        data.append(contentsOf: bulkID)
        data.append(type.data)
        data.append(UInt32(metadata.count).data)
        data.append(contentsOf: metadata)
        data.append(UInt32(content.count).data)
        data.append(contentsOf: content)
        self.data = data
    }
}
