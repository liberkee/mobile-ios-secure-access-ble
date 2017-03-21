//
//  BLEChallengerTests.swift
//  BLE
//
//  Created by Ke Song on 04.07.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import XCTest
import CryptoSwift

@testable import SecureAccessBLE

/// Testing BLE challenger service
class BLEChallengerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     Helper functio for xor calculation
     
     - parameter a: first parameter for calculation
     - parameter b: second parameter for calculation
     
     - returns: results of calculation
     */
    func xor(_ a: [UInt8], b:[UInt8]) -> [UInt8] {
        var xored = [UInt8](repeating: 0, count: a.count)
        for i in 0..<xored.count {
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
     To test challenge sid message
     */
    func testChalengeWithSIDMessage() {
        let crypto = AesCbcTestCryptoManager()
        
        /// the raw data from sending message to SID
        let nc = [0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01,0x01] as [UInt8]
        ///nc = Cipher.randomIV(16)
        
        /// decrypted message from online crypto caculation tool http://extranet.cryptomathic.com/aescalc/index
        let checkB0 = [0xF9,0x06,0xA2,0xE8,0x95,0xC3,0x57,0xE8,0x2F,0xE8,0xE0,0x55,0x66,0x91,0xCD,0xB1] as [UInt8]
        
        ///  the real SID response message from device
        let b1 = [0xb9,0x6a,0xf1,0x31,0xb9,0x69,0x06,0xdc,0x68,0x61,0x99,0x2c,0xf4,0x2e,0x36,0x03] as [UInt8]
        let b2 = [0x8b,0x30,0x4e,0xde,0x05,0x9b,0xfb,0xb4,0x52,0x92,0x51,0x53,0xe0,0xae,0x8b,0x87] as [UInt8]
        let b2data = Data(bytes: UnsafePointer<UInt8>(b2), count: b2.count)
        
        let b2decData = crypto.decryptRawData(b2data as Data) as Data
        let r3 = xor(b1, b: b2decData.bytes)
        ///  app calculation results
        let permutatedR3 = rotate(r3, inverse: true)
        let ncData = Data(bytes: UnsafePointer<UInt8>(nc), count: nc.count)
        let b0Data = crypto.encryptRawMessage(ncData as Data) as Data
        
        /// the calculation from app functions
        let b0 = b0Data.bytes
        
        /// check if the encryted results between BLE-functions and online tool the same
        XCTAssertEqual(checkB0, b0, "Tests with encrypting SidMessage failed")
        
        let checkB0Data = Data(bytes:checkB0)
        let checkNc = crypto.decryptRawData(checkB0Data) as Data
        
        ///  check decrypted message from web tool identical with original message
        XCTAssertEqual(checkNc.bytes, nc, "Tests with decrypting SidMessage failed")
        
        ///  decrypted message from app function identical with original message
        XCTAssertEqual(permutatedR3, nc, "Tests with Chalenge SidMessage failed")
    }
}
