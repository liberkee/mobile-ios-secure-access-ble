//: Playground - noun: a place where people can play

import CryptoSwift

protocol SorcMessagePayload {
    var data: NSData { set get }
}

enum SorcMessageID: UInt8 {
    case handshake = 0x01
    case phoneTest = 0x10
    case sorcTest = 0x13
    case serviceGrant = 0x20
    case serviceGrantTrigger = 0x30
    case mtuRequest = 0x06
    case mtuReceive = 0x07
    case notValid = 0xFF
}

struct Payload: SorcMessagePayload {
    init(data: NSData) {
        self.data = data
    }

    var data: NSData
}

struct SorcMessage {
    var id: SorcMessageID {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        data.getBytes(&byteArray, length: 1)
        if let validValue = SorcMessageID(rawValue: byteArray[0]) {
            return validValue
        } else {
            return .notValid
        }
    }

    var message: NSData {
        return data.subdata(with: NSMakeRange(1, data.length - 1)) as NSData
    }

    var data: NSData

    init(rawData: NSData) {
        data = rawData
    }

    init(id: SorcMessageID, payload: SorcMessagePayload) {
        let payloadData = payload.data
        let frameData = NSMutableData()
        var idByte = id.rawValue
        frameData.append(&idByte, length: 1)
        frameData.append(payloadData as Data)
        data = frameData
    }
}

protocol CryptoManager {
    func encryptMessage(message: SorcMessage) -> NSData
    func decryptData(data: NSData) -> SorcMessage
}

extension CryptoManager {
    func encryptMessage(message: SorcMessage) -> NSData {
        return message.data
    }

    func decryptData(data: NSData) -> SorcMessage {
        return SorcMessage(rawData: data)
    }
}

public struct ZeroByte: Padding {
    public init() {
    }

    public func add(to bytes: [UInt8], blockSize: Int) -> [UInt8] {
        let padding = blockSize - bytes.count
        var withPadding = bytes
        for _ in 0 ..< padding {
            withPadding.append(UInt8(0))
        }
        return withPadding
    }

    public func remove(from bytes: [UInt8], blockSize _: Int?) -> [UInt8] {
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

    private var key = [0x55, 0x0E, 0x84, 0x00, 0xE2, 0x9B, 0x11, 0xD4, 0xA7, 0x16, 0x44, 0x66, 0x55, 0x44, 0x00, 0x02] as [UInt8]
    private var iv = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]

    func encryptMessage(message: SorcMessage) -> NSData {
        do {
            let messageData: Data = message.data as Data
            let bytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC, padding: ZeroByte()).encrypt(messageData.bytes)
            let data = NSData(bytes: bytes, length: bytes.count)
            return data
        } catch {
            fatalError("Can not encrypt SorcMessage")
        }
    }

    func encryptRawMessage(message: NSData) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC, padding: ZeroByte()).encrypt((message as Data).bytes)
            let data = NSData(bytes: bytes, length: bytes.count)
            return data
        } catch {
            fatalError("Can not encrypt SorcMessage")
        }
    }

    func decryptData(data: NSData) -> SorcMessage {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC, padding: ZeroByte()).decrypt((data as Data).bytes)
            let data = NSData(bytes: bytes, length: bytes.count)
            let message = SorcMessage(rawData: data)
            return message
        } catch {
            fatalError("Can not decrypt SorcMessage")
        }
    }

    func decryptRawData(data: NSData) -> NSData {
        do {
            let bytes: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC, padding: ZeroByte()).decrypt((data as Data).bytes)
            let data = NSData(bytes: bytes, length: bytes.count)
            return data
        } catch {
            fatalError("Can not decrypt SorcMessage")
        }
    }
}

func xor(a: [UInt8], b: [UInt8]) -> [UInt8] {
    var xored = [UInt8](repeating: 0, count: a.count)
    for i in 0 ..< xored.count {
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
        permutedBytes.insert(temp!, at: 0)
    }
    return permutedBytes
}

// --- nc ---
let nc = [0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00] as [UInt8] // nc

// --- b0 ---
let data = NSData(bytes: nc, length: nc.count)
let crypto = AesCbcCryptoManager()
let b0Data = crypto.encryptRawMessage(message: data)
let b0 = (b0Data as Data).bytes

// --- b1, b2 ---
let b1 = [0x7E, 0xB3, 0xD6, 0x0F, 0x0E, 0xCF, 0x02, 0xA6, 0xBC, 0xFB, 0xAF, 0x56, 0x08, 0x83, 0xB6, 0xC0] as [UInt8] // b1
let b2 = [0x46, 0x50, 0x46, 0x80, 0xA9, 0xC1, 0x10, 0x2A, 0x91, 0x8E, 0xAB, 0xBE, 0x8E, 0xC6, 0x32, 0x93] as [UInt8] // b2

// --- r3 ---
let b2data = NSData(bytes: b2, length: b2.count)
let b2decData = crypto.decryptRawData(data: b2data)

let r3 = xor(a: b1, b: (b2decData as Data).bytes) // r3
let r3Data = NSData(bytes: r3, length: r3.count)

// --- Check Permuted r3 == nc ---
let permutatedR3 = rotate(bytes: r3, inverse: true)
if nc == permutatedR3 {
    // var length: UInt16 {
    let length: UInt16
    //    let data = Data()
    var byteArray = [UInt8](repeating: 0x0, count: 1)
    //        (data as Data).copyBytes(to: &byteArray, from: 2..<4)
    // return UInt16(data.count)
    // return UnsafePointer<UInt16>(byteArray).pointee
    // }
    debugPrint("Correct")
}

// --- nr ---
let b1dec = crypto.decryptRawData(data: NSData(bytes: b1, length: b1.count))
let nr = xor(a: b0, b: (b1dec as Data).bytes) // nr
let nrData = NSData(bytes: nr, length: nr.count)

// --- r5 ---
let r5 = rotate(bytes: nr, inverse: false) // r5
let r5Data = NSData(bytes: r5, length: r5.count)

// --- b3 ---
let unencryptedB3 = xor(a: r5, b: b2)
let unencB3Data = NSData(bytes: unencryptedB3, length: unencryptedB3.count)

let b3Data = crypto.encryptRawMessage(message: unencB3Data)
let b3 = (b3Data as Data).bytes // b3

let sessionKey = [
    nr[0], nr[1], nr[2], nr[3],
    nc[0], nc[1], nc[2], nc[3],
    nr[12], nr[13], nr[14], nr[15],
    nc[12], nc[13], nc[14], nr[15]
]

// let sessionKeyData = NSData(bytes: sessionKey, lengt
