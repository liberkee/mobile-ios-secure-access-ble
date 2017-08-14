//
//  CryptoManager.swift
//  HSM
//
//  Created by Sebastian Stüssel on 18.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation

/**
 *  All Transport layer messages shall be encrypted. Crypto manager will be used for endryting and decrypting
 *  the SORC messages
 */
protocol CryptoManager {
    /// cryption key
    var key: [UInt8] { get set }
    /**
     Encryption message to message Data

     - parameter message: incomming SorcMessage

     - returns: encrypted message data
     */
    mutating func encryptMessage(_ message: SorcMessage) -> Data

    /**
     To decrypte incomming data to SORC Message

     - parameter data: incomming Data, that will be decryted

     - returns: SORC message object decryted from incomming data
     */
    mutating func decryptData(_ data: Data) -> SorcMessage

    /**
     To decrypte incomming data to SORC data

     - parameter data: incomming Data, that will be decryted

     - returns: SORC Data object decryted from incomming data
     */
    func decryptRawData(_ data: Data) -> Data
}

/// Extension endpoint
extension CryptoManager {
    /**
     To decrypte incomming data to SORC data

     - parameter data: incomming Data, that will be decryted

     - returns: SORC Data object decryted from incomming data
     */
    func decryptRawData(_ data: Data) -> Data {
        return data
    }
}
