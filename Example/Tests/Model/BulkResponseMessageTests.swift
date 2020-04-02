//
//  BulkResponseMessageTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Priya Khatri on 31.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE

// swiftlint:disable line_length
class BulkResponseMessageTests: QuickSpec {
    override func spec() {
        describe("init from data") {
            var sut: BulkResponseMessage?
            beforeEach {
                let data = Data([
                    0x02, // protocol version
                    0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                    0x04, 0x00, 0x00, 0x00, // anchor length, little endian uint32
                    0xAA, 0xBB, 0xAA, 0xBB, // anchor
                    0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
                    0xAA, 0xBB, 0xCC, 0xDD, 0xEE, // revision
                    0x01, 0x00, 0x00, 0x00 // message, uint32
                ])
                sut = try? BulkResponseMessage(rawData: data)
            }
            it("should not be nil") {
                expect(sut).toNot(beNil())
            }
            it("does contain appropriate bulk id") {
                let bulkID: [UInt8] = [0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF]
                expect(sut?.bulkID) == bulkID
            }
            it("does contain appropriate anchor data") {
                let anchor: [UInt8] = [0xAA, 0xBB, 0xAA, 0xBB]
                expect(sut?.anchor) == anchor
            }
            it("does conatin appropriate revision data") {
                let revision: [UInt8] = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE]
                expect(sut?.revision) == revision
            }
            it("does conatin appropriate message value") {
                let message = 1
                expect(sut?.message) == message
            }
            context("parse inappropriate protocol version") {
                it("does throw error") {
                    let data = Data([
                        0x06, // inappropriate protocol version
                        0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                        0x04, 0x00, 0x00, 0x00, // anchor length, little endian uint32
                        0xAA, 0xBB, 0xAA, 0xBB, // anchor
                        0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
                        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, // revision
                        0x01, 0x00, 0x00, 0x00 // message, uint32
                    ])
                    expect { try BulkResponseMessage(rawData: data) }.to(throwError(BulkResponseMessage.Error.unsupportedBulkProtocolVersion))
                }
            }
            context("parse inappropriate anchor") {
                it("does throw error") {
                    let data = Data([
                        0x02, // protocol version
                        0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                        0x0A, 0x04, 0x00, 0x00, 0x00, // inappropriate anchor length, little endian uint32
                        0xAA, 0xBB, 0xAA, 0xBB, // anchor
                        0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
                        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, // revision
                        0x01, 0x00, 0x00, 0x00 // message, uint32
                    ])
                    expect { try BulkResponseMessage(rawData: data) }.to(throwError(BulkResponseMessage.Error.badFormat))
                }
            }
            context("parse inappropriate revision") {
                it("does throw error") {
                    let data = Data([
                        0x02, // protocol version
                        0x01, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xBA, 0xFF, // bulk id
                        0x04, 0x00, 0x00, 0x00, // anchor length, little endian uint32
                        0xAA, 0xBB, 0xAA, 0xBB, // anchor
                        0x0A, 0x05, 0x00, 0x00, 0x00, // inappropriate revision length, little endian uint32
                        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, // revision
                        0x01, 0x00, 0x00, 0x00 // message, uint32
                    ])
                    expect { try BulkResponseMessage(rawData: data) }.to(throwError(BulkResponseMessage.Error.badFormat))
                }
            }
        }
    }
}
