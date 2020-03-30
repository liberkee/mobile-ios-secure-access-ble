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
        describe("init from data") {
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
                    0x02, 0x00, 0x00, 0x00, // metadata length, little endian uint32
                    0xAA, 0xBB, // metadata
                    0x04, 0x00, 0x00, 0x00, // content length, little endian uint32
                    0xCC, 0xDD, 0xEE, 0xFF // content
                ]

                expect(sut.data.bytes) == expectedBytesArray
            }
        }
        describe("init from mobile bulk") {
            it("does not throw") {
                let bulkID = UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")!
                let mobileBulk = try! MobileBulk(bulkID: bulkID, type: .configBulk, metadata: "", content: "")
                expect { try BulkTransmitMessage(mobileBulk: mobileBulk) }.toNot(throwError())
            }

            it("transforms data to properties") {
                let uuidString = "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f"
                let metaData = "METADATA"
                let content = "SFVG" // "HUF" base 64 encoded
                let bulkID = UUID(uuidString: uuidString)!
                let mobileBulk = try! MobileBulk(bulkID: bulkID, type: .configBulk, metadata: metaData, content: content)

                let sut = try! BulkTransmitMessage(mobileBulk: mobileBulk)

                expect(String(data: Data(sut.bulkID), encoding: .utf8)) == uuidString
                expect(String(data: Data(sut.metadata), encoding: .ascii)) == metaData
                expect(String(data: Data(sut.content), encoding: .utf8)) == "HUF"
            }
        }
    }
}
