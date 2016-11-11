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
     
     - parameter message: incomming SIDMessage
     
     - returns: encrypted message data
     */
    mutating func encryptMessage(_ message: SIDMessage) -> Data {
        return message.data as Data
    }
    
    /**
     To decrypte incomming data to SID Message
     
     - parameter data: incomming Data, that will be decryted
     
     - returns: SID message object decryted from incomming data
     */
    mutating func decryptData(_ data: Data) -> SIDMessage {
        return SIDMessage(rawData: data)
    }
    

}
