//
//  BulkTransferTests.swift
//  SecureAccessBLE_Tests
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE
import XCTest

// swiftlint:disable function_body_length
class BulkTransferTests: QuickSpec {
    struct ConfigBulkResponses: Codable {
        let configBulks: [ConfigBulk]
    }

    struct ConfigBulk: Codable {
        let bulkID: String
        let configBulkMetadata: ConfigBulkMetadata
        let content: String

        enum CodingKeys: String, CodingKey {
            case bulkID = "bulkId"
            case configBulkMetadata, content
        }
    }

    struct ConfigBulkMetadata: Codable {
        let revision, anchor, signature, firmwareVersion: String
        let deviceID: String

        enum CodingKeys: String, CodingKey {
            case revision, anchor, signature, firmwareVersion
            case deviceID = "deviceId"
        }
    }

    override func spec() {
        var configBulkResponses: ConfigBulkResponses!
        var configBulk: ConfigBulk!

        describe("configResponse") {
            beforeEach {
                let path = Bundle(for: type(of: self)).path(forResource: "config_bulk", ofType: "json")
                let responseData = try! Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                configBulkResponses = try! decoder.decode(ConfigBulkResponses.self, from: responseData)
                configBulk = configBulkResponses.configBulks[0]
            }
            context("parse config bulks") {
                var configMetadata: String = ""
                var configContext: [UInt8]?
                beforeEach {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try! encoder.encode(configBulk!.configBulkMetadata)
                    configMetadata = String(data: data, encoding: String.Encoding.utf8)!
                    configContext = configBulk.content.bytes
                }
                it("should map") {
                    let sut = try? MobileBulk(bulkID: configBulk!.bulkID,
                                              type: .configBulk,
                                              metadata: configMetadata,
                                              content: configContext!)
                    expect(sut).toNot(beNil())
                }
                it("does contain deviceID") {
                    let bulkID = "686e61e2-2967-4cfa-bd35-3eb3df4ed13e"
                    let mobileBulk = try? MobileBulk(bulkID: configBulk!.bulkID,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configContext!)
                    let receivedbulkID = String(bytes: mobileBulk!.bulkId, encoding: .utf8)
                    expect(bulkID) == receivedbulkID
                }
                it("does contain metadata") {
                    let mobileBulk = try? MobileBulk(bulkID: configBulk!.bulkID,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configContext!)
                    expect(mobileBulk?.metadata).notTo(beNil())
                }
                it("does contain content") {
                    let mobileBulk = try? MobileBulk(bulkID: configBulk!.bulkID,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configContext!)
                    expect(mobileBulk?.content).notTo(beNil())
                }
            }
        }
    }
}
