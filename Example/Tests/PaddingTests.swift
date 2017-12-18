//
//  PaddingTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Oleg Langer on 05.12.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

@testable import SecureAccessBLE
import XCTest

class PaddingTests: XCTestCase {

    func test_zeroPadding_ifChunkIsEmpty_doesNotAddPadding() {
        // GIVEN
        let bytes: [UInt8] = []
        let zeroPadding = ZeroByte()

        // WHEN
        let result = zeroPadding.add(to: bytes, blockSize: 16)

        // THEN
        XCTAssertEqual(result, [])
    }

    func test_zeroPadding_ifChunkHAsData_AddsPadding() {
        // GIVEN
        let bytes: [UInt8] = [0xFF, 0xFF]
        let zeroPadding = ZeroByte()

        // WHEN
        let result = zeroPadding.add(to: bytes, blockSize: 16)

        // THEN
        let expectedResult: [UInt8] = [0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        XCTAssertEqual(result, expectedResult)
    }

    func test_zeroPadding_ifChunkSizeBiggerThenBlockSize_AddsPadding() {
        // GIVEN
        let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        let zeroPadding = ZeroByte()

        // WHEN
        let result = zeroPadding.add(to: bytes, blockSize: 4)

        // THEN
        let expectedResult: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00]
        XCTAssertEqual(result, expectedResult)
    }
}
