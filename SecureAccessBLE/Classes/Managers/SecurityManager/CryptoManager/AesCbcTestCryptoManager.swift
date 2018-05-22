//
//  AesCbcTestCryptoManager.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils
import CryptoSwift

/**
 *  A crypto manager for tests, that handles messages and feedback from session layer and from transport layer.
 *  The messages must be send encrypted and signed using crypto algorithum AES-CBC with AES-CMAC
 */
struct AesCbcTestCryptoManager: CryptoManager {
    /**
     Initialization point

     - parameter key: En(De)cryption key
     - parameter iv:  IV

     - returns: Cryption maanger object
     */
    init(key: [UInt8]? = nil, iv: [UInt8]? = nil) {
        if let k = key {
            self.key = k
        }
        if let iv = iv {
            self.iv = iv
        }
    }

    /// The session key after successful established cryption
    internal var key = [0x42, 0xE8, 0x44, 0x7A, 0xA1, 0x94, 0x4E, 0x9C, 0x49, 0xCF, 0xCA, 0xA0, 0x53, 0x63, 0x11, 0xC8] as [UInt8]
    /// The default IV [Zero] as UInt8 bytes
    fileprivate var iv = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]

    /**
     To encrypt incomming message

     - parameter message: incomming SORC Message object that will be encrypted

     - returns: sending data encrypted from SORC Message
     */
    func encryptMessage(_ message: SorcMessage) -> Data {
        do {
            let bytes: [UInt8] = try AES(key: key, blockMode: .CBC(iv: iv), padding: Padding.zeroPadding).encrypt((message.data as Data).bytes)
            let data = Data(bytes: bytes)
            return data
        } catch {
            HSMLog(message: "BLE - Can not encrypt SorcMessage", level: .error)
            fatalError("Can not encrypt SorcMessage")
        }
    }

    /**
     All sending message will be encrypted to NSData object for Data transfer

     - parameter message: comming SORC message object to encrypt

     - returns: encrypted out put NSData object
     */
    func encryptRawMessage(_ message: Data) -> Data {
        do {
            let bytes: [UInt8] = try AES(key: key, blockMode: .CBC(iv: iv), padding: Padding.zeroPadding).encrypt((message as Data).bytes)
            let data = Data(bytes: bytes)
            return data
        } catch {
            HSMLog(message: "BLE - Can not encrypt SorcMessage", level: .error)
            fatalError("Can not encrypt SorcMessage")
        }
    }

    /**
     To decrypte incomming data to SORC Message

     - parameter data: incomming Data, that will be decryted

     - returns: SORC message object decryted from incomming data
     */
    func decryptData(_ data: Data) -> SorcMessage {
        do {
            let bytes: [UInt8] = try AES(key: key, blockMode: .CBC(iv: iv), padding: Padding.zeroPadding).encrypt((data as Data).bytes)
            let data = Data(bytes: bytes)
            let message = SorcMessage(rawData: data)
            return message
        } catch {
            HSMLog(message: "BLE - Can not decrypt SorcMessage", level: .error)
            fatalError("Can not decrypt SorcMessage")
        }
    }

    /**
     Only for tests used function to decrypt NSData object to NSData

     - parameter data: comming NSData object will be decrypted

     - returns: decrypted NSData object as out put
     */
    func decryptRawData(_ data: Data) -> Data {
        do {
            let bytes: [UInt8] = try AES(key: key, blockMode: .CBC(iv: iv), padding: Padding.zeroPadding).encrypt((data as Data).bytes)
            let data = Data(bytes: bytes)
            return data
        } catch {
            HSMLog(message: "BLE - Can not decrypt SorcMessage", level: .error)
            fatalError("Can not decrypt SorcMessage")
        }
    }
}
