//
//  AesCbcCryptoManager.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//


import CryptoSwift
import Foundation

/**
 *  A crypto manager, that handles messages and feedback from session layer and from transport layer.
 *  The messages must be send encrypted and signed using crypto algorithum AES-CBC with AES-CMAC
 */
struct AesCbcCryptoManager: CryptoManager {
    /// Default key as [Zero]
    internal var key = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]
    /// Default encryption IV [zero]
    fileprivate var encIV = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]
    /// Default decryption IV [zero]
    fileprivate var decIV = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]
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

     - parameter message: incomming SORC Message object that will be encrypted

     - returns: sending data encrypted from SORC Message
     */
    mutating func encryptMessage(_ message: SorcMessage) -> Data {
        do {
            let data = message.data
            let mod = (data.count + CryptoHeader.length) % 16
            let paddingLength = 16 - mod
            let encData = try createEncData(data, paddingLength: paddingLength)
            let mac = createShortMac(encData, iv: encIV)
            let encDataWithMac = NSMutableData()
            encDataWithMac.append(encData)
            encDataWithMac.append(Data(bytes: mac))
            let ivData = encData.subdata(in: encData.count - 16 ..< encData.count)
            encIV = [UInt8](ivData)

            return encDataWithMac as Data

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
    mutating func decryptData(_ data: Data) -> SorcMessage {
        do {
            guard checkMac(data) else {
                HSMLog(message: "BLE - MAC is invalid", level: .error)
                return SorcMessage(id: SorcMessageID.notValid, payload: EmptyPayload())
            }

            let dataWithoutMac = data.subdata(in: 0 ..< data.count - 8) // NSMakeRange(0, data.count-8))
            let decryptedBytes = try AES(key: key, blockMode: .CBC(iv: decIV), padding: Padding.noPadding).decrypt(dataWithoutMac.bytes)
            decIV = dataWithoutMac.subdata(in: dataWithoutMac.count - 16 ..< dataWithoutMac.count).bytes
            let messageDataBytes = Array(decryptedBytes[1 ..< decryptedBytes.count - 1])
            let message = SorcMessage(rawData: Data(bytes: messageDataBytes))
            return message
        } catch {
            return SorcMessage(id: SorcMessageID.notValid, payload: EmptyPayload())
            // fatalError("Can not decrypt SorcMessage")
        }
    }

    /**
     Incomming message data will be encryted using AES-CBC preparing for sending

     - parameter data:          incomming message data from sending message
     - parameter paddingLength: length of data, that should be padded to message data

     - throws: nothing

     - returns: encrypted message data as NSData object
     */
    func createEncData(_ data: Data, paddingLength: Int) throws -> Data {
        let paddingData = Data(bytes: [UInt8](repeating: 0x0, count: paddingLength))
        let header = CryptoHeader(direction: .toSorc, padding: UInt8(paddingLength))
        let dataWithPadding = NSMutableData()
        dataWithPadding.append(header.data)
        dataWithPadding.append(data)
        dataWithPadding.append(paddingData)
        let theData: Data = dataWithPadding as Data
        let bytes = try AES(key: key, blockMode: .CBC(iv: encIV), padding: Padding.noPadding).encrypt(theData.bytes)
        let encData = Data(bytes: bytes)
        return encData
    }

    /**
     CMAC (Cipher-based Message Authentication Code) will be needed for decrypting message

     - parameter data: incomming data

     - returns: short form from MAC
     */
    func createShortMac(_ data: Data, iv: [UInt8]) -> [UInt8] {
        var mac = [UInt8](repeating: 0x0, count: 16)

        let prefixedArray = iv + data.bytes

        do {
            let cmac = try CMAC(key: key)
            mac = try cmac.authenticate(prefixedArray)
        } catch let error {
            HSMLog(message: error.localizedDescription, level: .error)
        }

        let shortMacSlice = mac[mac.count - 8 ..< mac.count]
        return Array(shortMacSlice)
    }

    /**
     To check if MAC valid

     - parameter data: mac data

     - returns: valid or not
     */
    func checkMac(_ data: Data) -> Bool {
        guard data.count > 8 else { return false }

        let encodedData = data.subdata(in: 0 ..< data.count - 8) // NSMakeRange(0, data.count-8))
        let sorcMac = data.subdata(in: data.count - 8 ..< data.count) // NSMakeRange(data.count-8, 8)).arrayOfBytes()
        let shortMac = createShortMac(encodedData, iv: decIV)

        let result = sorcMac.bytes == shortMac ? true : false
        return result
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

     - toSorc:      Message to SORC
     - toPhone:     Message from SORC to Phone
     - noDirection: Message has uncertainly direction
     */
    enum CryptoMessageDirection: UInt8 {
        case toSorc = 0x00
        case toPhone = 0x01
        case noDirection = 0xFF
    }

    /// Header object as NSData
    fileprivate var data = Data()

    /// Padding as UInt8
    var padding: UInt8 {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, count: 1)
        let padding = byteArray[0] >> 4
        return padding
    }

    /// See above definition CryptoMessageDirection
    var direction: CryptoMessageDirection {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, from: 1 ..< 2)
        if let validValue = CryptoMessageDirection(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .noDirection
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
        let headerData = Data([headerDataBytes])
        data = headerData
    }

    /**
     Initialization only with rawdata

     - parameter rawData: raw data for header

     - returns: Header as NSData object
     */
    init(rawData: Data) {
        data = rawData
    }
}
