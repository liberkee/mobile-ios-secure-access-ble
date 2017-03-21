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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    /**
     Testing Encrpting (SID-message) and Decrypting (Response data) with Zero security crypto manager
     */
    func testZeroSecurityCryption() {
        
        /// to initialize a zero Crypto manager for encrypting and decrypting
        var zeroCryptor = ZeroSecurityManager()
        
        /// Testing message with get MTU request
        let mtuRequestMessage = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())
        
        /// Mock data from SID with response MTU Receive Data
        let mtuReceiveData = [0x07, 0x9b, 0x00] as [UInt8]
        
        /// testing with encrypting message
        XCTAssertNotNil(zeroCryptor.encryptMessage(mtuRequestMessage), "Crypto manager returned NIL for encrpting message")
        
        let mtuReceivMessage = zeroCryptor.decryptData(Data(bytes:mtuReceiveData))
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
        let sessionKey = [0xa9,0xba,0x14,0xa1,0x50,0x20,0x9f,0xe2,0x30,0xe7,0x1a,0x2b,0x78,0x0f,0x06,0x45] as [UInt8]
        
        /// Cryptor initialized with established sessionKey
        var aesCryptor = AesCbcCryptoManager(key: sessionKey)
        
        /// Sending message for service grant .LockStatus
        let sendingMessage = SIDMessage(id: SIDMessageID.serviceGrant, payload: ServiceGrantRequest(grantID: ServiceGrantID.lockStatus))
        
        /// Received data from SID, for Servicetrigger results "LOCKED"
        let receivedServiceTrigerData = [0xd3,0x7d,0x36,0x92,0xbe,0xb0,0xf2,0xde,0x36,0xd8,0x75,0xf9,0xbb,0x4c,0xf3,0x00,0xf5,0xf9,0x54,0x83,0x62,0x54,0xbf,0xaf] as [UInt8]
        
        /// Resting with encrypting message
        XCTAssertNotNil(aesCryptor.encryptMessage(sendingMessage), "Crypto manager returned NIL for encrpting message!")
        
        /// Received data will decrypted to SID message object with AES crypto manager
        let receivedMessage = aesCryptor.decryptData(Data(bytes:receivedServiceTrigerData))
        
        /// Testing if received message will be correctly decrypted
        XCTAssertNotNil(receivedMessage, "Crypto manager returned NIL for decrpting message!")
        
        /// To builde service grant trigger with decrypted SID message
        let serviceGrantTrigger = ServiceGrantTrigger(rawData: receivedMessage.message)
        
        /// Testing if service grant trigger has ID .Lockstatus
        XCTAssertEqual(serviceGrantTrigger.id, ServiceGrantID.lockStatus, "Crypto manager returned wrong service grant ID!")
        
        /// Testing if service grant trigger has result .Locked
        XCTAssertEqual(serviceGrantTrigger.result, ServiceGrantTrigger.ServiceGrantResult.Locked, "Crypto manager returned wrong service grant result!")
    }
}
