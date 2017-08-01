//
//  BLECtyptorTests.swift
//  BLE
//
//  Created by Ke Song on 04.07.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE

class BLECryptorTests: XCTestCase {

    /**
     Testing Encrpting (SID-message) and Decrypting (Response data) with Zero security crypto manager
     */
    func testZeroSecurityCryption() {

        /// to initialize a zero Crypto manager for encrypting and decrypting
        var zeroCryptor = ZeroSecurityManager()

        /// Testing message with get MTU request
        let mtuRequestMessage = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())

        /// Mock data from SID with response MTU Receive Data
        let mtuReceiveData = [0x07, 0x9B, 0x00] as [UInt8]

        /// testing with encrypting message
        XCTAssertNotNil(zeroCryptor.encryptMessage(mtuRequestMessage), "Crypto manager returned NIL for encrpting message")

        let mtuReceivMessage = zeroCryptor.decryptData(Data(bytes: mtuReceiveData))
        /// testing with decrypting received message data
        XCTAssertNotNil(mtuReceivMessage, "Crypto manager returned NIL for decrpting message")

        /// Payload for MTUReceivMessage
        let payload = MTUSize(rawData: mtuReceivMessage.message)

        /// To get MTU Size from SID message
        let mtuSize = payload.mtuSize

        /// testing if response message is valid
        XCTAssertNotNil(mtuSize, "Crypto manager has not received MTU Size")

        // The mtu size responses from SID, 155 was defined for ios APP
        XCTAssert(payload.mtuSize == 155, "Crypto manager has wrong MTUSize")
    }

    /**
     Testing Encrpting (SID-Message) and Decrypting (Response-Data) with AES-crypto manager
     */
    func testAesCbcCryption() {

        /// Established sessionKey for further AES CryptoManager
        let sessionKey = [0xA9, 0xBA, 0x14, 0xA1, 0x50, 0x20, 0x9F, 0xE2, 0x30, 0xE7, 0x1A, 0x2B, 0x78, 0x0F, 0x06, 0x45] as [UInt8]

        /// Cryptor initialized with established sessionKey
        var aesCryptor = AesCbcCryptoManager(key: sessionKey)

        /// Sending message for service grant .LockStatus
        let sendingMessage = SIDMessage(id: SIDMessageID.serviceGrant, payload: ServiceGrantRequest(grantID: ServiceGrantID.lockStatus))

        /// Received data from SID, for Servicetrigger results "LOCKED"
        let receivedServiceTrigerData = [0xD3, 0x7D, 0x36, 0x92, 0xBE, 0xB0, 0xF2, 0xDE, 0x36, 0xD8, 0x75, 0xF9, 0xBB, 0x4C, 0xF3, 0x00, 0xF5, 0xF9, 0x54, 0x83, 0x62, 0x54, 0xBF, 0xAF] as [UInt8]

        /// Resting with encrypting message
        XCTAssertNotNil(aesCryptor.encryptMessage(sendingMessage), "Crypto manager returned NIL for encrpting message!")

        /// Received data will decrypted to SID message object with AES crypto manager
        let receivedMessage = aesCryptor.decryptData(Data(bytes: receivedServiceTrigerData))

        /// Testing if received message will be correctly decrypted
        XCTAssertNotNil(receivedMessage, "Crypto manager returned NIL for decrpting message!")

        /// To builde service grant trigger with decrypted SID message
        let serviceGrantTrigger = ServiceGrantTrigger(rawData: receivedMessage.message)

        /// Testing if service grant trigger has ID .Lockstatus
        XCTAssertEqual(serviceGrantTrigger.id, ServiceGrantID.lockStatus, "Crypto manager returned wrong service grant ID!")

        /// Testing if service grant trigger has result .Locked
        XCTAssertEqual(serviceGrantTrigger.result, ServiceGrantTrigger.ServiceGrantResult.locked, "Crypto manager returned wrong service grant result!")
    }

    func test_AesCbcCryptoManager_decryptData_ifMacIsInvalid_messageIdIsNotValid() {

        // Given
        let sessionKey = [0x00, 0xBA, 0x14, 0xA1, 0x50, 0x20, 0x9F, 0xE2, 0x30, 0xE7, 0x1A, 0x2B, 0x78, 0x0F, 0x06, 0x45] as [UInt8]
        var aesCryptor = AesCbcCryptoManager(key: sessionKey)
        let receivedServiceTriggerData = Data(bytes: [0x30, 0x02, 0x00, 0x00] as [UInt8])

        // When
        let receivedMessage = aesCryptor.decryptData(receivedServiceTriggerData)

        // Then
        XCTAssertEqual(receivedMessage.id, .notValid)
    }
}
