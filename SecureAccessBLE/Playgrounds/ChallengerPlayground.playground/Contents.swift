//: Playground - noun: a place where people can play

import UIKit
import CryptoSwift

protocol SIDMessagePayload {
    var data: NSData {set get}
}

enum SIDMessageID: UInt8 {
    case Handshake = 0x01
    case PhoneTest = 0x10
    case SidTest = 0x13
    case ServiceGrant = 0x20
    case ServiceGrantTrigger = 0x30
    case MTURequest = 0x06
    case MTUReceive = 0x07
    case NotValid = 0xFF
}

struct Payload: SIDMessagePayload {
    init(data: NSData) {
        self.data = data
    }
    var data: NSData
}


struct SIDMessage {
    var id: SIDMessageID {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, length:1)
        if let validValue = SIDMessageID(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .NotValid
        }
    }
    
    var message: NSData {
        return data.subdataWithRange(NSMakeRange(1, data.length-1))
    }
    
    var data: NSData
    
    init(rawData: NSData) {
        data = rawData
    }
    
    init(id: SIDMessageID, payload: SIDMessagePayload) {
        let payloadData = payload.data
        let frameData = NSMutableData()
        var idByte = id.rawValue
        frameData.appendBytes(&idByte, length: 1)
        frameData.appendData(payloadData)
        data = frameData
    }
}


protocol CryptoManager {
    func encryptMessage(message: SIDMessage) -> NSData
    func decryptData(data: NSData) -> SIDMessage
}

extension CryptoManager {
    func encryptMessage(message: SIDMessage) -> NSData {
        return message.data
    }
    
    func decryptData(data: NSData) -> SIDMessage {
        return SIDMessage(rawData: data)
    }
}

public struct ZeroByte: Padding {
    
    public init() {
        
    }
    
    public func add(bytes: [UInt8] , blockSize:Int) -> [UInt8] {
        let padding = blockSize - bytes.count
        var withPadding = bytes
        for _ in 0..<padding {
            withPadding.append(UInt8(0))
        }
        return withPadding
    }
    
    public func remove(bytes: [UInt8], blockSize:Int?) -> [UInt8] {
        var cleanBytes = bytes
        
        for _ in bytes where cleanBytes.last == 0 {
            cleanBytes.removeLast()
        }
        
        return cleanBytes
    }
}

struct AesCbcCryptoManager: CryptoManager {
    
    init(key: [UInt8]? = nil, iv: [UInt8]? = nil) {
        if let k = key {
            self.key = k
        }
        
        if let iv = iv {
            self.iv = iv
        }
    }

    private var key = [0x55,0x0E,0x84,0x00,0xE2,0x9B,0x11,0xD4,0xA7,0x16,0x44,0x66,0x55,0x44,0x00,0x02] as [UInt8]
    private var iv =  [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    
    func encryptMessage(message: SIDMessage) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv,blockMode: CipherBlockMode.CBC)!.encrypt(message.data.arrayOfBytes(), padding: ZeroByte())

            let data = NSData.withBytes(bytes)
            return data
        } catch {
            fatalError("Can not encrypt SIDMessage")
        }
    }
    
    func encryptRawMessage(message: NSData) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv,blockMode: CipherBlockMode.CBC)!.encrypt(message.arrayOfBytes(), padding: ZeroByte())
            let data = NSData.withBytes(bytes)
            return data
        } catch {
            fatalError("Can not encrypt SIDMessage")
        }
    }
    
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

func xor(a: [UInt8], b:[UInt8]) -> [UInt8] {
    var xored = [UInt8](count: a.count, repeatedValue: 0)
    for i in 0..<xored.count {
        xored[i] = a[i] ^ b[i]
    }
    return xored
}

func rotate(bytes: [UInt8], inverse: Bool) -> [UInt8] {
    
    var permutedBytes = bytes
    if inverse {
        let temp = permutedBytes.first
        permutedBytes.removeFirst()
        permutedBytes.append(temp!)
    } else {
        let temp = permutedBytes.last
        permutedBytes.removeLast()
        permutedBytes.insert(temp!, atIndex: 0)
    }
    return permutedBytes
}


//--- nc ---
let nc  = [0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01,0x00] as [UInt8] //nc

//--- b0 ---
let data = NSData.withBytes(nc)
let crypto = AesCbcCryptoManager()
let b0Data = crypto.encryptRawMessage(data)
let b0 = b0Data.arrayOfBytes()


//--- b1, b2 ---
let b1 = [0x7E,0xB3,0xD6,0x0F,0x0E,0xCF,0x02,0xA6,0xBC,0xFB,0xAF,0x56,0x08,0x83,0xB6,0xC0] as [UInt8] //b1
let b2 = [0x46,0x50,0x46,0x80,0xA9,0xC1,0x10,0x2A,0x91,0x8E,0xAB,0xBE,0x8E,0xC6,0x32,0x93] as [UInt8] //b2

//--- r3 ---
let b2data = NSData.withBytes(b2)
let b2decData = crypto.decryptRawData(b2data)

let r3 = xor(b1, b: b2decData.arrayOfBytes()) //r3
let r3Data = NSData.withBytes(r3)

//--- Check Permuted r3 == nc ---
let permutatedR3 = rotate(r3, inverse: true)
if nc == permutatedR3 {
    print("Correct")
}



//--- nr ---
let b1dec = crypto.decryptRawData(NSData.withBytes(b1))
let nr = xor(b0, b: b1dec.arrayOfBytes()) //nr
let nrData = NSData.withBytes(nr)


//--- r5 ---
let r5 = rotate(nr, inverse: false) //r5
let r5Data = NSData.withBytes(r5)


//--- b3 ---
let unencryptedB3 = xor(r5, b: b2)
let unencB3Data = NSData.withBytes(unencryptedB3)

let b3Data = crypto.encryptRawMessage(unencB3Data)
let b3 = b3Data.arrayOfBytes() //b3

let sessionKey = [
    nr[0],nr[1],nr[2],nr[3],
    nc[0],nc[1],nc[2],nc[3],
    nr[12],nr[13],nr[14],nr[15],
    nc[12],nc[13],nc[14],nr[15]
]

let sessionKeyData = NSData.withBytes(sessionKey)



