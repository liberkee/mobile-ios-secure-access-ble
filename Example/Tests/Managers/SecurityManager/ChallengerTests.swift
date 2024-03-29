//
//  ChallengerTests.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import CryptoSwift
@testable import SecureAccessBLE
import XCTest

class ChallengerTests: XCTestCase {
    /**
     Helper functio for xor calculation

     - parameter a: first parameter for calculation
     - parameter b: second parameter for calculation

     - returns: results of calculation
     */
    func xor(_ a: [UInt8], b: [UInt8]) -> [UInt8] {
        var xored = [UInt8](repeating: 0, count: a.count)
        for i in 0 ..< xored.count {
            xored[i] = a[i] ^ b[i]
        }
        return xored
    }

    /**
     mathmatic calculation for retation

     - parameter bytes:   incomming bytes to rotate
     - parameter inverse: inverse or not

     - returns: results bytes after rotation
     */
    func rotate(_ bytes: [UInt8], inverse: Bool) -> [UInt8] {
        var permutedBytes = bytes
        if inverse {
            let temp = permutedBytes.first
            permutedBytes.removeFirst()
            permutedBytes.append(temp!)
        } else {
            let temp = permutedBytes.last
            permutedBytes.removeLast()
            permutedBytes.insert(temp!, at: 0)
        }
        return permutedBytes
    }

    /**
     To test challenge SORC message
     */
    func testChallengeWithSorcMessage() {
        let crypto = AesCbcTestCryptoManager()

        /// the raw data from sending message to SORC
        let nc = [0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x01] as [UInt8]
        /// nc = Cipher.randomIV(16)

        /// decrypted message from online crypto caculation tool http://extranet.cryptomathic.com/aescalc/index
        let checkB0 = [0xF9, 0x06, 0xA2, 0xE8, 0x95, 0xC3, 0x57, 0xE8, 0x2F, 0xE8, 0xE0, 0x55, 0x66, 0x91, 0xCD, 0xB1] as [UInt8]

        ///  the real SORC response message from device
        let b1 = [0xB9, 0x6A, 0xF1, 0x31, 0xB9, 0x69, 0x06, 0xDC, 0x68, 0x61, 0x99, 0x2C, 0xF4, 0x2E, 0x36, 0x03] as [UInt8]
        let b2 = [0x8B, 0x30, 0x4E, 0xDE, 0x05, 0x9B, 0xFB, 0xB4, 0x52, 0x92, 0x51, 0x53, 0xE0, 0xAE, 0x8B, 0x87] as [UInt8]
        let b2data = Data(b2)

        let b2decData = crypto.decryptRawData(b2data)
        let r3 = xor(b1, b: b2decData.bytes)
        ///  app calculation results
        let permutatedR3 = rotate(r3, inverse: true)
        let ncData = Data(nc)
        let b0Data = crypto.encryptRawMessage(ncData)

        /// the calculation from app functions
        let b0 = b0Data.bytes

        /// check if the encryted results between BLE-functions and online tool the same
        XCTAssertEqual(checkB0, b0, "Tests with encrypting SorcMessage failed")

        let checkB0Data = Data(checkB0)
        let checkNc = crypto.decryptRawData(checkB0Data)

        ///  check decrypted message from web tool identical with original message
        XCTAssertEqual(checkNc.bytes, nc, "Tests with decrypting SorcMessage failed")

        ///  decrypted message from app function identical with original message
        XCTAssertEqual(permutatedR3, nc, "Tests with Challenge SorcMessage failed")
    }
}
