//
//  MobileBulkResponseTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Priya Khatri on 01.04.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE

// swiftlint:disable line_length
class MobileBulkResponseTests: QuickSpec {
    override func spec() {
        describe("recieved BulkResponseMessage") {
            var bulkResponseMessage: BulkResponseMessage!
            beforeEach {
                let data = Data([
                    0x02, // protocol version
                    0x37, 0x41, 0x35, 0x31, 0x41, 0x42, 0x30, 0x31, 0x36, 0x30, 0x46, 0x35, 0x34, 0x33, 0x37, 0x38, // bulk id
                    0x04, 0x00, 0x00, 0x00, // anchor length, little endian uint32
                    0x4F, 0x4D, 0x47, 0x21, // anchor
                    0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
                    0x48, 0x65, 0x6C, 0x6C, 0x6F, // revision
                    0x01, 0x00, 0x00, 0x00 // message, uint32
                ])
                bulkResponseMessage = try! BulkResponseMessage(rawData: data)
            }
            context("init from BulkResponseMessage") {
                var sut: MobileBulkResponse?
                beforeEach {
                    sut = try? MobileBulkResponse(bulkResponseMessage: bulkResponseMessage)
                }
                it("should map") {
                    expect(sut).toNot(beNil())
                }
                it("does contain bulkID") {
                    let bulkID = "7A51AB0160F54378"
                    expect(sut?.bulkID) == bulkID
                }
                it("does contain anchor") {
                    let anchor = "OMG!"
                    expect(sut?.anchor) == anchor
                }
                it("does contain revision") {
                    let revision = "Hello"
                    expect(sut?.revision) == revision
                }
                it("does contain message") {
                    let message = 1
                    expect(sut?.message) == message
                }
                context("does not contain proper bulkID") {
                    beforeEach {
                        let data = Data([
                            0x02, // protocol version
                            0x37, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                            0x04, 0x00, 0x00, 0x00, // anchor length, little endian uint32
                            0x4F, 0x4D, 0x47, 0x21, // anchor
                            0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
                            0x48, 0x65, 0x6C, 0x6C, 0x6F, // revision
                            0x01, 0x00, 0x00, 0x00 // message, uint32
                        ])
                        bulkResponseMessage = try? BulkResponseMessage(rawData: data)
                    }
                    it("throw bulkid error") {
                        expect {
                            try MobileBulkResponse(bulkResponseMessage: bulkResponseMessage)
                        }.to(throwError(MobileBulkResponse.Error.badBulkIDFormat))
                    }
                }
            }
        }
    }
}
