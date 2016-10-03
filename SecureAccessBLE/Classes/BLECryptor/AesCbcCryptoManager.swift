//
//  AesCbcCryptoManager.swift
//  HSM
//
//  Created by Sebastian Stüssel on 18.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation
import CryptoSwift
import OpenSSL

/**
 *  A crypto manager, that handles messages and feedback from session layer and from transport layer.
 *  The messages must be send encrypted and signed using crypto algorithum AES-CBC with AES-CMAC
 */
struct AesCbcCryptoManager: CryptoManager {
    /// Default key as [Zero]
    internal var key = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    /// Default encryption IV [zero]
    private var encIV = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    /// Default decryption IV [zero]
    private var decIV = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    /**
     Initialization point
     
     - parameter key: En(De)cryption key as [UInt]
     
     - returns: Cryption manager object
     */
    init(key: [UInt8]) {
        self.key = key
    }
    /**
     To encrypt incomming message
     
     - parameter message: incomming SID Message object that will be encrypted
     
     - returns: sending data encrypted from SID Message
     */
    mutating func encryptMessage(message: SIDMessage) -> NSData {
        do {
            let data = message.data
            let mod = (data.length + CryptoHeader.length) % 16
            let paddingLength = 16 - mod
            let encData = try self.createEncData(data, paddingLength: paddingLength)
            let mac = self.createShortMac(encData)
            let encDataWithMac = NSMutableData()
            encDataWithMac.appendData(encData)
            encDataWithMac.appendData(NSData.withBytes(mac))
            let ivData = encData.subdataWithRange(NSMakeRange(encData.length-16, 16))
            self.encIV = ivData.arrayOfBytes()
            
            return encDataWithMac

        } catch {
            fatalError("Can not encrypt SIDMessage")
        }
    }
    
    /**
     To decrypte incomming data to SID Message
    
     - parameter data: incomming Data, that will be decryted
     
     - returns: SID message object decryted from incomming data
     */
    mutating func decryptData(data: NSData) -> SIDMessage {
        do {
            if self.checkMac(data) == false {
                print("Huihuihui")
            }
            
            let dataWithoutMac = data.subdataWithRange(NSMakeRange(0, data.length-8))
            let decryptedBytes = try AES(key: self.key, iv: self.decIV, blockMode: .CBC)!.decrypt(dataWithoutMac.arrayOfBytes(), padding: NoPadding())
            self.decIV = dataWithoutMac.subdataWithRange(NSMakeRange(dataWithoutMac.length-16, 16)).arrayOfBytes()
            
            let messageDataBytes = Array(decryptedBytes[1..<decryptedBytes.count-1])
            let message = SIDMessage(rawData: NSData.withBytes(messageDataBytes))
            return message
        } catch {
            return SIDMessage(id: SIDMessageID.NotValid, payload: EmptyPayload())
            //fatalError("Can not decrypt SIDMessage")
        }
    }
    
    /**
     Incomming message data will be encryted using AES-CBC preparing for sending
     
     - parameter data:          incomming message data from sending message
     - parameter paddingLength: length of data, that should be padded to message data
     
     - throws: nothing
     
     - returns: encrypted message data as NSData object
     */
    func createEncData(data: NSData, paddingLength: Int) throws -> NSData {
        let paddingData = NSData.withBytes([UInt8](count: paddingLength, repeatedValue: 0x0))
        let header = CryptoHeader(direction: .ToSid, padding: UInt8(paddingLength))
        let dataWithPadding = NSMutableData()
        dataWithPadding.appendData(header.data)
        dataWithPadding.appendData(data)
        dataWithPadding.appendData(paddingData)
        let bytes: [UInt8] = try AES(key: key, iv: self.encIV, blockMode: .CBC)!.encrypt(dataWithPadding.arrayOfBytes(),padding: NoPadding())
        let encData = NSData.withBytes(bytes)
        return encData
    }
    
    /**
      CMAC (Cipher-based Message Authentication Code) will be needed for decrypting message
     
     - parameter data: incomming data
     
     - returns: short form from MAC
     */
    func createShortMac(data: NSData) -> [UInt8] {
        
        var mac =  [UInt8](count: 16, repeatedValue: 0x0)
        var macLength = 0
        let ctx = CMAC_CTX_new()
        CMAC_Init(ctx, self.key, self.key.count, EVP_aes_128_cbc(), nil)
        CMAC_Update(ctx, self.encIV, self.encIV.count)
        CMAC_Update(ctx, data.arrayOfBytes(), data.length)
        CMAC_Final(ctx, &mac, &macLength)
        CMAC_CTX_free(ctx)
        let shortMac = mac[macLength-8..<macLength]
        return Array(shortMac)
    }
    
    /**
     To check if MAC valid
     
     - parameter data: mac data
     
     - returns: valid or not
     */
    func checkMac(data: NSData) -> Bool {
        if data.length > 8 {
            let encodedData = data.subdataWithRange(NSMakeRange(0, data.length-8))
            let sidMac = data.subdataWithRange(NSMakeRange(data.length-8, 8)).arrayOfBytes()
            
            var mac =  [UInt8](count: 16, repeatedValue: 0x0)
            var macLength = 0
            let ctx = CMAC_CTX_new()
            CMAC_Init(ctx, self.key, self.key.count, EVP_aes_128_cbc(), nil)
            CMAC_Update(ctx, self.decIV, self.decIV.count)
            CMAC_Update(ctx, encodedData.arrayOfBytes(), encodedData.length)
            CMAC_Final(ctx, &mac, &macLength)
            CMAC_CTX_free(ctx)
            let shortMacSlice = mac[macLength-8..<macLength]
            let shortMac = Array(shortMacSlice)
            if sidMac == shortMac {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

/**
 *  Header for Encryption data
 */
struct CryptoHeader {
    /// header length
    static let length = 1
    /**
     Define Message type as enumeration
     
     - ToSid:       Message to SID
     - ToPhone:     Message from SID to Phone
     - NoDirection: Message has uncertainly direction
     */
    enum CryptoMessageDirection: UInt8 {
        case ToSid = 0x00
        case ToPhone = 0x01
        case NoDirection = 0xFF
    }
    
    /// Header object as NSData
    private var data = NSData()
    
    /// Padding as UInt8
    var padding: UInt8 {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        self.data.getBytes(&byteArray, length:1)
        let padding = byteArray[0]>>4
        return padding
    }
    
    /// See above definition CryptoMessageDirection
    var direction:CryptoMessageDirection {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        self.data.getBytes(&byteArray, range: NSMakeRange(1, 1))
        if let validValue = CryptoMessageDirection(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .NoDirection
        }
    }
    
    /**
     Initialization point for Header
     
     - parameter direction: Message direction
     - parameter padding:   padding to a certaily data length
     
     - returns: Header object as NSData
     */
    init(direction: CryptoMessageDirection, padding: UInt8) {
        let paddingBits = padding << 4
        let directionBits = direction.rawValue
        let headerDataBytes = paddingBits | directionBits
        let headerData = NSData.withBytes([headerDataBytes])
        self.data = headerData
    }
    
    /**
     Initialization only with rawdata
     
     - parameter rawData: raw data for header
     
     - returns: Header as NSData object
     */
    init(rawData: NSData) {
        self.data = rawData
    }
}