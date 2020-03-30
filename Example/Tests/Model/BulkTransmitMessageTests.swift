//
//  BulkTransmitMessageTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Oleg Langer on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE

class BulkTransmitMessageTests: QuickSpec {
    override func spec() {
        describe("init") {
            it("data has appropriate structure") {
                let sut = BulkTransmitMessage(
                    bulkID: [0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF],
                    type: 1,
                    metadata: [0xAA, 0xBB],
                    content: [0xCC, 0xDD, 0xEE, 0xFF]
                )

                let expectedBytesArray: [UInt8] = [
                    0x60, // message id
                    0x02, // protocol version
                    0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                    0x01, 0x00, 0x00, 0x00, // type, uint32
                    0x02, 0x00, 0x00, 0x00, // metadata length, uint32
                    0xAA, 0xBB, // metadata
                    0x04, 0x00, 0x00, 0x00, // content length, uint32
                    0xCC, 0xDD, 0xEE, 0xFF // content
                ]

                expect(sut.data.bytes) == expectedBytesArray
            }
        }
    }
}
