//
//  MobileBulk.swift
//  SecureAccessBLE
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct MobileBulk {
    private var bulkId: [UInt8]
    private var type: Int
    private var metadata: [UInt8]
    private var content: [UInt32]

    init(bulkID: String, type: Int, metadata: String, content: [UInt32]) {
        bulkId = bulkID.utf8Array
        self.type = type
        self.metadata = metadata.map { return $0.asciiValue! }
        self.content = content
    }
}

extension String {
    var utf8Array: [UInt8] {
        return Array(utf8)
    }
}
