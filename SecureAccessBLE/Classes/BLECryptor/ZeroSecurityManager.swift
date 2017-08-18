//
//  ZeroSecurityManager.swift
//  HSM
//
//  Created by Sebastian Stüssel on 18.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  Default Cryptomanager with 'Zero' key, if encryption was not estabilisched
 */
struct ZeroSecurityManager: CryptoManager {
    /// default key [Zero] for zero security Cryptor
    var key: [UInt8] = [0x00] as [UInt8]
    /**
     Encryption message to message Data

     - parameter message: incomming SorcMessage

     - returns: encrypted message data
     */
    func encryptMessage(_ message: SorcMessage) -> Data {
        return message.data as Data
    }

    /**
     To decrypte incomming data to SORC Message

     - parameter data: incomming Data, that will be decryted

     - returns: SORC message object decryted from incomming data
     */
    func decryptData(_ data: Data) -> SorcMessage {
        return SorcMessage(rawData: data)
    }
}
