//
//  AesCbcTestCryptoManager.swift
//  BLE
//
//  Created by Ke Song on 30.05.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import OpenSSL
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
    internal var key = [0x42,0xe8,0x44,0x7a,0xa1,0x94,0x4e,0x9c,0x49,0xcf,0xca,0xa0,0x53,0x63,0x11,0xc8] as [UInt8]
    /// The default IV [Zero] as UInt8 bytes
    private var iv =  [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    
    /**
     To encrypt incomming message
     
     - parameter message: incomming SID Message object that will be encrypted
     
     - returns: sending data encrypted from SID Message
     */
    func encryptMessage(message: SIDMessage) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv,blockMode: CipherBlockMode.CBC)!.encrypt(message.data.arrayOfBytes(), padding: ZeroByte())
            
            let data = NSData.withBytes(bytes)
            return data
        } catch {
            fatalError("Can not encrypt SIDMessage")
        }
    }
    
    /**
     All sending message will be encrypted to NSData object for Data transfer
     
     - parameter message: comming SID message object to encrypt
     
     - returns: encrypted out put NSData object
     */
    func encryptRawMessage(message: NSData) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv,blockMode: CipherBlockMode.CBC)!.encrypt(message.arrayOfBytes(), padding: ZeroByte())
            let data = NSData.withBytes(bytes)
            return data
        } catch {
            fatalError("Can not encrypt SIDMessage")
        }
    }
    
    /**
     To decrypte incomming data to SID Message
     
     - parameter data: incomming Data, that will be decryted
     
     - returns: SID message object decryted from incomming data
     */
    func decryptData(data: NSData) -> SIDMessage {
        do {
            let bytes: [UInt8] = try AES(key: key,iv: iv, blockMode: CipherBlockMode.CBC)!.decrypt(data.arrayOfBytes(), padding: ZeroByte())
            let data = NSData.withBytes(bytes)
            let message = SIDMessage(rawData: data)
            return message
        } catch {
            fatalError("Can not decrypt SIDMessage")
        }
    }
    
    /**
     Only for tests used function to decrypt NSData object to NSData
     
     - parameter data: comming NSData object will be decrypted
     
     - returns: decrypted NSData object as out put
     */
    func decryptRawData(data: NSData) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key,iv: iv, blockMode: CipherBlockMode.CBC)!.decrypt(data.arrayOfBytes(), padding: ZeroByte())
            let data = NSData.withBytes(bytes)
            return data
        } catch {
            fatalError("Can not decrypt SIDMessage")
        }
    }
}
