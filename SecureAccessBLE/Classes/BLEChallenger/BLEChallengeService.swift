//
//  BLEChallengeService.swift
//  BLE
//
//  Created by Ke Song on 20.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CryptoSwift

/**
 Defines errors for Challenge and (en)decryption
 
 */
enum BLEChallengerError: Error {
    /// wrong resonse donot match
    case challengeResponseDoNotMatch
    /// Response was not accepted
    case challengeResponseWasNotAccepted
    /// Response currupted
    case challengeResponseIsCorrupt
    /// AES Cryption failed No crypto
    case aesCryptoNotInitialised
    /// AES Encryption failed
    case aesEncryptionFailed
    /// AES Decryption failed
    case aesDecryptionFailed
    /// No Message
    case noChallengeMessage
}

/**
 *  All delegate functions, the BLE-Challenger offers
 */
protocol BLEChallengeServiceDelegate {
    /**
     Challenger reports need to send message
     
     - parameter message: the sending message object
     */
    func challengerWantsSendMessage(_ message: SIDMessage)
    
    /**
     Challenger did finished
     
     - parameter sessionKey: The encryption key for further cryption
     */
    func challengerFinishedWithSessionKey(_ sessionKey: [UInt8])
    
    /**
     Challenger aborted
     
     - parameter error: error description
     */
    func challengerAbort(_ error: BLEChallengerError)
    
    /**
     Challenger will send blob
     */
    func challengerNeedsSendBlob()
}

/**
 *  BLE ChallengeService provides a mutual challenge / response mechanism. 
 *  The challenge response mecfhanism shall mutually authenticate SID and smart device.
 *  A session key will be resulted to encrypt the SID smart device communication.
 *  prerequistite shall be that the smart device and SID posses a symmetric pre-shared key, that
 *  shall be provided by the secure access platform via the distributed lease token.
 *  The lease token should be encrypted with public key of smart device and SID and
 *  signed by the platform server.
 *  More infos for challenge response protocol see also the reference:
 *  https://www.emsec.rb.de/media/crypto/veroeffentlichungen/2011/11/16/chameleon.pdf
 *  The challenge response mechanism shall operate as follow:
 
 *  1. The smartphone (App) picks a random 128-bit nonce nc and AES-encrypts nc with shared AES key: k(auth) results b0.
 *  2. b0 is sent to the SID
 *  3. SID decryts b0 r0 = encAES(k(auth), b0)
 *  4. SID permutes r0 r1 = P(r0)
 *  5. SID picks a random 128-bit nonce nr and encrypts nr in CBC mode b1 = encAES(k(auth), nr XOR b0)
 *  6. SID encrypts r1 in CBC mode b2 = encAES(k(auth); r1 XOR b1)
 *  7. SID sends b1 and b2 to the Smartphone App.
 *  8. The App decryts b2 in CBC mode: r3 = decAES (k(auth); b2) XOR b1
 *  9. The App checks if permuted noce is valid: P(invert)(r3) = nc, if not the protocol is aborted, if equal, the
 *      SID noce is decrypted: r4 = decAES(k(auth); b1) XOR b0
 *  10. The decrypted nonce is permuted: r5 = P(r4) and AES-encrypted: b3 = encAES(k(auth); r5 XOR b2)
 *  11. b3 is sent to SID
 *  12. SID decrypts b3: r6 = decAES(k(auth); b3) XOR b2
 *  13. SID checks if the permuted nonce is valid: if P(invert)(r6) does not equal to nr, the protoco is aborted,
 *      if equal, the authentication is complete
 *  14. Both SID and App have the same session key:
 *      ks = nr[0...3] || nc[0...3] || nr[12...15] || nc[12...15]
 *  
 *  note: || indicates concatenation and a[i...j] indicates the bytes 'i' to 'j' of an array a
 */
struct BLEChallengeService {
    /// random generated
    fileprivate var nc: [UInt8]
    /// original data
    fileprivate var b0 = [UInt8]()
    /// encrypted from b0
    fileprivate var b1 = [UInt8]()
    /// encrypted from b1
    fileprivate var b2 = [UInt8]()
    /// decrypted from b1 b2
    fileprivate var b3 = [UInt8]()
    /// nr calculated from b
    fileprivate var nr = [UInt8]()
    /// r3 must equal to nc
    fileprivate var r3 = [UInt8]()
    /// iverse of nr
    fileprivate var r5 = [UInt8]()
    
    /// DeviceId as string
    fileprivate let leaseId: String
    /// Sid id as String
    fileprivate let sidId: String
    /// Lease token id as String
    fileprivate let leaseTokenId: String
    /// Sid access Key as String
    fileprivate let sidAccessKey: String
    /// Default cryptor
    fileprivate let crypto: AES
    /// Challenger Service Delegate object
    var delegate: BLEChallengeServiceDelegate?
    
    /**
     init function for BLE Challenger object
     
     - parameter deviceId:     device id as String see also Moddel: SecureAccess.deviceId
     - parameter sidId:        sid id as String see also Moddel: SecureAccess.sidId
     - parameter leaseTokenId: lease token id as String see also Moddel: SecureAccess.leaseTokenId
     - parameter sidAccessKey: sid access key as String see also Moddel: SecureAccess.sidAccessKey
     
     - returns: new object for BLE Challenger
     */
    init?(leaseId: String, sidId: String, leaseTokenId: String, sidAccessKey: String) {
        self.leaseId = leaseId
        self.sidId = sidId
        self.leaseTokenId = leaseTokenId
        self.sidAccessKey = sidAccessKey
        
//        self.nc = [0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01,0x01] as [UInt8]
        self.nc = AES.randomIV(16)
        
        guard let sharedKey = self.sidAccessKey.dataFromHexadecimalString() else {
            return nil
        }
        
        let key = sharedKey.bytes//.arrayOfBytes()
        
        do {
            let aesCrypto = try AES(key: key, padding: ZeroByte())
            self.crypto = aesCrypto
        } catch {
            return nil
        }
    }
    
    /**
     Should only be called, when a BLE Challenger should be started.
     
     - throws: Challenger Error if Encryption failed
     */
    mutating func beginChallenge() throws {
        do {
//            print ("begin to challenge with nc: \(Data.withBytes(self.nc))")
            try self.b0 = self.crypto.encrypt(self.nc)
            let payload = PhoneToSidChallenge(leaseId: self.leaseId, sidID: self.sidId, leaseTokenID: self.leaseTokenId, challenge: self.b0)
            
            let message = SIDMessage(id: .challengePhone, payload: payload)
            self.delegate?.challengerWantsSendMessage(message)
        } catch {
            print ("AES Encryption failed!")
            throw BLEChallengerError.aesEncryptionFailed
        }
    }
    
    /**
     Handles all incoming challenge responses from SID.
     
     - parameter response: received response as SID message
     
     - throws:
     */
    mutating func handleReceivedChallengerMessage(_ response: SIDMessage) throws {
        print("Resonse message with id:\(response.id)")
        switch response.id {
        case .ltAck:
            try self.beginChallenge()
        case .badChallengeSidResponse:
            print("BLE Challenge needs send blob!")
            self.delegate?.challengerNeedsSendBlob()
        case .challengeSidResponse:
            try self.continueChallenge(response)
        default:
            self.delegate?.challengerAbort(BLEChallengerError.noChallengeMessage)
        }
    }
    
    /**
     Aditional challenge message according to the first response messge from SID
     
     - parameter response: response message from first step challenge
     
     - throws: nothing
     */
    mutating fileprivate func continueChallenge(_ response: SIDMessage) throws {
        let message = SidToPhoneResponse(rawData: response.message)
        if message.b1.count == 0 || message.b2.count == 0 {
            throw BLEChallengerError.challengeResponseIsCorrupt
        }
        self.b1 = message.b1
        self.b2 = message.b2
        try self.r3 = self.calculateR3(self.b1, b2: self.b2)
        try (self.nr, self.r5) = self.calculateN5(self.b0, b1: self.b1)
        try self.b3 = self.calculateB3(self.r5, b2: self.b2)
        
        let payload = PhoneToSidResponse(response: self.b3)
        let responseMessage = SIDMessage(id: SIDMessageID.challengePhoneResonse, payload: payload)
        self.delegate?.challengerWantsSendMessage(responseMessage)
        if nr.count > 15 && nc.count > 15 {
            let sessionKey = [
                nr[0],nr[1],nr[2],nr[3],
                nc[0],nc[1],nc[2],nc[3],
                nr[12],nr[13],nr[14],nr[15],
                nc[12],nc[13],nc[14],nc[15]
            ]
            print("challenger finished with session key: \(Data(bytes:sessionKey))")
            self.delegate?.challengerFinishedWithSessionKey(sessionKey)
        }
    }
    
    /**
     Mathmatic calculation for (inverse)rotation of incomming bytes (Matrix)
     
     - parameter bytes:   incomming bytes that should be reteted
     - parameter inverse: inverse or not as bool
     
     - returns: new rotated bytes (Matrix)
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
     Logical exclusive or calculation for incomming operands
     
     - parameter a: one of both involved operands
     - parameter b: another one from operands
     
     - returns: result
     */
    fileprivate func xor(_ a: [UInt8], b:[UInt8]) -> [UInt8] {
        var xored = [UInt8](repeating: 0, count: a.count)
        for i in 0..<xored.count {
            xored[i] = a[i] ^ b[i]
        }
        return xored
    }
    
    /**
     App decryts b2 in CBC mode: r3 = decAES (k(auth); b2) XOR b1
     
     - parameter b1: b1 = encAES(k(auth), nr XOR b0)
     - parameter b2: response from SID
     
     - throws: if challenge aborted
     
     - returns: r3
     */
    fileprivate func calculateR3(_ b1: [UInt8], b2: [UInt8]) throws -> [UInt8] {
        do {
            let r3Temp = try crypto.decrypt(b2)//, padding: ZeroByte())
            let r3 = xor(r3Temp, b: b1)
            
            let permutatedR3 = rotate(r3, inverse: true)
            
            //  check if P(invert)(r3) = nc, if not the protocol is aborted
            if self.nc != permutatedR3 {
                self.delegate?.challengerWantsSendMessage(SIDMessage(id: SIDMessageID.badChallengePhoneResponse, payload: EmptyPayload()))
                throw BLEChallengerError.challengeResponseDoNotMatch
            }
            return r3
            
        } catch {
            throw BLEChallengerError.aesEncryptionFailed
        }
    }
    
    /**
     To calculate r4 = decAES(k(auth); b2) XOR b1
     
     - parameter b0: is sent to SID
     - parameter b1: b1 = encAES(k(auth), nr XOR b0)
     
     - throws: decryption error
     
     - returns: [r4 r5]
     */
    fileprivate func calculateN5(_ b0: [UInt8], b1: [UInt8]) throws -> (nr: [UInt8], n5: [UInt8]) {
        do {
            let decryptedB1 =  try crypto.decrypt(b1)//, padding: ZeroByte())
            let nr = xor(decryptedB1, b: b0)    //  r4
            let n5 = rotate(nr, inverse: false) //  r5
            return (nr, n5)
            
        } catch {
            throw BLEChallengerError.aesDecryptionFailed
        }
    }
    
    /**
     To calculate b3 = encAES(k(auth); r5 XOR b2) sending to SID for second step challenge
     
     - parameter r5: calculated from b0 and b1
     - parameter b2: response from SID at first step challenge
     
     - throws: Challenge Error if challenge aborted
     
     - returns: sending message b3, for required session key
     */
    fileprivate func calculateB3(_ r5: [UInt8], b2:[UInt8]) throws -> [UInt8] {
        let b3Temp = xor(r5, b: b2)
        do {
            let b3 = try crypto.encrypt(b3Temp)///, padding: ZeroByte())
            return b3
        } catch {
            throw BLEChallengerError.aesEncryptionFailed
        }
    }
    
}
