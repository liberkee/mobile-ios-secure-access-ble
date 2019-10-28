//
//  BLECryptorTests.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

@testable import SecureAccessBLE
import XCTest

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!

class BLECryptorTests: XCTestCase {
    /**
     Testing Encrpting (SORC-message) and Decrypting (Response data) with Zero security crypto manager
     */
    func testZeroSecurityCryption() {
        /// to initialize a zero Crypto manager for encrypting and decrypting
        let zeroCryptor = ZeroSecurityManager()

        /// Testing message with get MTU request
        let message = SorcMessage(id: SorcMessageID.challengePhone, payload: DefaultMessage())

        /// Mock data from SORC with response MTU Receive Data
        let mtuReceiveData = [0x07, 0x9B, 0x00] as [UInt8]

        /// testing with encrypting message
        XCTAssertNotNil(zeroCryptor.encryptMessage(message), "Crypto manager returned NIL for encrpting message")

        let mtuReceivMessage = zeroCryptor.decryptData(Data(mtuReceiveData))
        /// testing with decrypting received message data
        XCTAssertNotNil(mtuReceivMessage, "Crypto manager returned NIL for decrpting message")

        /// Payload for MTUReceivMessage
        let payload = DefaultMessage(rawData: mtuReceivMessage.message)

        /// To get MTU Size from SORC message
        let firstByte = Int(payload.data.bytes.first!)

        // The mtu size responses from SORC, 155 was defined for ios APP
        XCTAssert(firstByte == 155, "Crypto manager has wrong MTUSize")
    }

    /**
     Testing Encrpting (SORC-Message) and Decrypting (Response-Data) with AES-crypto manager
     */
    func testAesCbcCryption() {
        let serviceGrantIDA = UInt16(0x03)

        /// Established sessionKey for further AES CryptoManager
        let sessionKey = [0xA9, 0xBA, 0x14, 0xA1, 0x50, 0x20, 0x9F, 0xE2, 0x30, 0xE7, 0x1A, 0x2B, 0x78, 0x0F, 0x06, 0x45] as [UInt8]

        /// Cryptor initialized with established sessionKey
        var aesCryptor = AesCbcCryptoManager(key: sessionKey)

        /// Sending message for service grant .LockStatus
        let sendingMessage = SorcMessage(id: SorcMessageID.serviceGrant, payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA))

        /// Received data from SORC, for Servicetrigger results "LOCKED"
        let receivedData = [
            0xD3, 0x7D, 0x36, 0x92, 0xBE, 0xB0, 0xF2, 0xDE, 0x36, 0xD8, 0x75, 0xF9, 0xBB, 0x4C, 0xF3, 0x00, 0xF5, 0xF9, 0x54, 0x83,
            0x62, 0x54, 0xBF, 0xAF
        ] as [UInt8]

        /// Resting with encrypting message
        XCTAssertNotNil(aesCryptor.encryptMessage(sendingMessage), "Crypto manager returned NIL for encrpting message!")

        /// Received data will decrypted to SORC message object with AES crypto manager
        let receivedMessage = aesCryptor.decryptData(Data(receivedData))

        /// Testing if received message will be correctly decrypted
        XCTAssertNotNil(receivedMessage, "Crypto manager returned NIL for decrpting message!")

        let response = ServiceGrantResponse(sorcID: sorcIDA, message: receivedMessage)!

        /// Testing if service grant trigger has ID .Lockstatus
        XCTAssertEqual(response.serviceGrantID, serviceGrantIDA, "Crypto manager returned wrong service grant ID!")

        /// Testing if service grant trigger has result .Locked
        XCTAssertEqual(response.responseData, "LOCKED", "Crypto manager returned wrong service grant result!")
    }

    func test_AesCbcCryptoManager_decryptData_ifMacIsInvalid_messageIdIsNotValid() {
        // Given
        let sessionKey = [0x00, 0xBA, 0x14, 0xA1, 0x50, 0x20, 0x9F, 0xE2, 0x30, 0xE7, 0x1A, 0x2B, 0x78, 0x0F, 0x06, 0x45] as [UInt8]
        var aesCryptor = AesCbcCryptoManager(key: sessionKey)
        let receivedServiceTriggerData = Data([0x30, 0x02, 0x00, 0x00] as [UInt8])

        // When
        let receivedMessage = aesCryptor.decryptData(receivedServiceTriggerData)

        // Then
        XCTAssertEqual(receivedMessage.id, .notValid)
    }
}
