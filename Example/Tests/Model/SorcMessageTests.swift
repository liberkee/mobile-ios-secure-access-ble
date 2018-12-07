// SorcMessageTests.swift
// SecureAccessBLE_Tests

// Created on 07.12.18.
// Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.

@testable import SecureAccessBLE
import XCTest

class SorcMessageTests: XCTestCase {
    func test_blobRequestMessage() {
        let sorcMessage = SorcMessage(rawData: Data(bytes: [
            SorcMessageID.ltBlobRequest.rawValue,
            0x01, // blob type
            0x00, 0x00, 0x00, 0xFF // blob messsage counter
            ]))
        
        let blobRequest = try! BlobRequest(rawData: sorcMessage.message)

        XCTAssertEqual(blobRequest.blobMessageCounter, 255)
    }
}
