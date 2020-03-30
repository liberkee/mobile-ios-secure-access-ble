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
                beforeEach {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try! encoder.encode(configBulk!.configBulkMetadata)
                    configMetadata = String(data: data, encoding: String.Encoding.utf8)!
                }
                it("should map") {
                    let sut = try? MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                              type: .configBulk,
                                              metadata: configMetadata,
                                              content: configBulk.content)
                    expect(sut).toNot(beNil())
                }
                it("does contain bulkID") {
                    let bulkID = "686e61e2-2967-4cfa-bd35-3eb3df4ed13e"
                    let mobileBulk = try? MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configBulk.content)
                    let receivedbulkID = UUID(uuidString: bulkID)!
                    expect(mobileBulk?.bulkId) == receivedbulkID
                }
                it("does contain ascii encoded metadata") {
                    let mobileBulk = try? MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configBulk.content)
                    expect(String(data: mobileBulk!.metadata, encoding: .ascii)) == configMetadata
                }
                it("does contain content as base64 encoded data") {
                    let mobileBulk = try? MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                                     type: .configBulk,
                                                     metadata: configMetadata,
                                                     content: configBulk.content)
                    expect(mobileBulk?.content.base64EncodedString()) == configBulk.content
                }
                it("throws if content is in bad format") {
                    func createBulkWithBrokenContent() throws {
                        _ = try MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                           type: .configBulk,
                                           metadata: configMetadata,
                                           content: "A_A_A_A_")
                    }

                    expect { try createBulkWithBrokenContent() }.to(throwError(MobileBulk.Error.contentFormat))
                }
                it("throws if metadata is in bad format") {
                    func createBulkWithBrokenContent() throws {
                        _ = try MobileBulk(bulkID: UUID(uuidString: configBulk.bulkID)!,
                                           type: .configBulk,
                                           metadata: "Ä",
                                           content: configBulk.content)
                    }

                    expect { try createBulkWithBrokenContent() }.to(throwError(MobileBulk.Error.metadataFormat))
                }
            }
        }
    }
}
